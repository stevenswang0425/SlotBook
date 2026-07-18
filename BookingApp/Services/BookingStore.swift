//
//  BookingStore.swift
//  SlotBook
//
//  In-memory booking repository + live availability state.
//  Single source of truth for reserved slots across open Item Detail screens.
//

import Foundation
import Observation
import SwiftUI

/// App-wide store of bookings and reserved slots (user + simulated remote).
@Observable
@MainActor
final class BookingStore {
    /// Newest-created first (lists re-sort as needed).
    private(set) var bookings: [Booking] = []

    /// All slot IDs currently unavailable (user bookings ∪ remote holds).
    private(set) var reservedSlotIDs: Set<UUID> = []

    /// Subset reserved by the real-time simulator (not user bookings).
    private(set) var remoteReservedSlotIDs: Set<UUID> = []

    /// Slot → item mapping for remote holds (toast targeting).
    private var remoteSlotItemIDs: [UUID: UUID] = [:]

    /// Latest availability notice for toast / analytics consumers.
    /// `id` changes every publish so SwiftUI `onChange` always fires.
    private(set) var lastNotice: SlotAvailabilityNotice?

    /// Monotonic counter bumped on every reservation mutation (cheap view invalidation).
    private(set) var reservationEpoch: UInt = 0

    var isEmpty: Bool { bookings.isEmpty }

    // MARK: - Queries

    func upcomingBookings(now: Date = Date()) -> [Booking] {
        bookings
            .filter { $0.isUpcoming(now: now) }
            .sorted { $0.slot.start < $1.slot.start }
    }

    func pastBookings(now: Date = Date()) -> [Booking] {
        bookings
            .filter { $0.isPast(now: now) }
            .sorted { $0.slot.start > $1.slot.start }
    }

    func booking(withID id: UUID) -> Booking? {
        bookings.first { $0.id == id }
    }

    func isSlotReserved(_ slotID: UUID) -> Bool {
        reservedSlotIDs.contains(slotID)
    }

    // MARK: - User bookings

    func add(_ booking: Booking) {
        if bookings.contains(where: { $0.id == booking.id }) { return }
        bookings.insert(booking, at: 0)
        if booking.status == .confirmed {
            reservedSlotIDs.insert(booking.slot.id)
            // If the simulator held this slot, promote it to a user booking.
            remoteReservedSlotIDs.remove(booking.slot.id)
            remoteSlotItemIDs[booking.slot.id] = nil
            publishNotice(
                SlotAvailabilityNotice(
                    kind: .taken,
                    slotID: booking.slot.id,
                    itemID: booking.item.id,
                    source: .localBooking,
                    message: "You're booked · \(booking.slot.rangeLabel())"
                )
            )
        }
        bumpEpoch()
    }

    /// Cancels a confirmed booking and releases its time slot.
    @discardableResult
    func cancel(id: UUID, at date: Date = Date()) -> Booking? {
        guard let index = bookings.firstIndex(where: { $0.id == id }) else { return nil }
        guard bookings[index].status == .confirmed else { return nil }

        let booking = bookings[index]
        bookings[index].status = .cancelled
        bookings[index].cancelledAt = date
        reservedSlotIDs.remove(booking.slot.id)
        publishNotice(
            SlotAvailabilityNotice(
                kind: .freed,
                slotID: booking.slot.id,
                itemID: booking.item.id,
                source: .localCancel,
                message: "Slot released · \(booking.slot.rangeLabel())"
            )
        )
        bumpEpoch()
        return bookings[index]
    }

    /// Optimistic local reserve (detail screen before/while confirming).
    func reserveSlot(_ slotID: UUID, itemID: UUID) {
        reservedSlotIDs.insert(slotID)
        bumpEpoch()
        publishNotice(
            SlotAvailabilityNotice(
                kind: .taken,
                slotID: slotID,
                itemID: itemID,
                source: .localBooking,
                message: "Slot reserved"
            )
        )
    }

    func releaseSlot(_ slotID: UUID) {
        reservedSlotIDs.remove(slotID)
        remoteReservedSlotIDs.remove(slotID)
        remoteSlotItemIDs[slotID] = nil
        bumpEpoch()
    }

    // MARK: - Remote (simulator)

    /// Marks a slot taken by a simulated remote user.
    func reserveRemoteSlot(_ slotID: UUID, itemID: UUID) {
        guard !reservedSlotIDs.contains(slotID) else { return }
        reservedSlotIDs.insert(slotID)
        remoteReservedSlotIDs.insert(slotID)
        remoteSlotItemIDs[slotID] = itemID
        bumpEpoch()
        publishNotice(
            SlotAvailabilityNotice(
                kind: .taken,
                slotID: slotID,
                itemID: itemID,
                source: .remoteBooking,
                message: "Someone just booked this slot"
            )
        )
    }

    /// Frees a simulator-held slot (never touches user bookings).
    func releaseRemoteSlot(_ slotID: UUID) {
        guard remoteReservedSlotIDs.contains(slotID) else { return }
        remoteReservedSlotIDs.remove(slotID)
        reservedSlotIDs.remove(slotID)
        let itemID = remoteSlotItemIDs[slotID] ?? UUID()
        remoteSlotItemIDs[slotID] = nil
        bumpEpoch()
        publishNotice(
            SlotAvailabilityNotice(
                kind: .freed,
                slotID: slotID,
                itemID: itemID,
                source: .remoteRelease,
                message: "A slot just opened up"
            )
        )
    }

    func clearAll() {
        bookings.removeAll()
        reservedSlotIDs.removeAll()
        remoteReservedSlotIDs.removeAll()
        remoteSlotItemIDs.removeAll()
        lastNotice = nil
        bumpEpoch()
    }

    // MARK: - Preview seed

    func seedPreviewData(now: Date = Date(), calendar: Calendar = .current) {
        clearAll()
        let catalog = MockItems.catalog
        guard catalog.count >= 3 else { return }

        if let todaySlot = firstAvailableSlot(for: catalog[0], on: now, calendar: calendar) {
            add(
                Booking.make(
                    item: catalog[0],
                    slot: todaySlot.slot,
                    date: todaySlot.day,
                    guestName: "Alex Rivera",
                    phoneDigits: "5551234567",
                    createdAt: now
                )
            )
        }

        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           let slot = firstAvailableSlot(for: catalog[1], on: tomorrow, calendar: calendar) {
            add(
                Booking.make(
                    item: catalog[1],
                    slot: slot.slot,
                    date: slot.day,
                    guestName: "Alex Rivera",
                    phoneDigits: "5551234567",
                    createdAt: now
                )
            )
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           let past = firstAvailableSlot(for: catalog[2], on: yesterday, calendar: calendar) {
            add(
                Booking.make(
                    item: catalog[2],
                    slot: past.slot,
                    date: past.day,
                    guestName: "Alex Rivera",
                    phoneDigits: "5551234567",
                    createdAt: yesterday
                )
            )
        }

        if let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now),
           let cancelled = firstAvailableSlot(for: catalog[3 % catalog.count], on: twoDaysAgo, calendar: calendar) {
            add(
                Booking.make(
                    item: catalog[3 % catalog.count],
                    slot: cancelled.slot,
                    date: cancelled.day,
                    guestName: "Alex Rivera",
                    phoneDigits: "5551234567",
                    createdAt: twoDaysAgo,
                    status: .cancelled,
                    cancelledAt: twoDaysAgo
                )
            )
        }
    }

    // MARK: - Private

    private func publishNotice(_ notice: SlotAvailabilityNotice) {
        lastNotice = notice
    }

    private func bumpEpoch() {
        reservationEpoch &+= 1
    }

    private func firstAvailableSlot(
        for item: Item,
        on day: Date,
        calendar: Calendar
    ) -> (day: Date, slot: TimeSlot)? {
        let start = calendar.startOfDay(for: day)
        let slots = MockSlots.slots(for: start, itemID: item.id, calendar: calendar)
        let pick = slots.first(where: { $0.isAvailable && calendar.component(.hour, from: $0.start) >= 10 })
            ?? slots.first(where: \.isAvailable)
            ?? slots.first
        guard let pick else { return nil }
        return (start, pick)
    }
}

// MARK: - Environment

private struct BookingStoreKey: EnvironmentKey {
    @MainActor static var defaultValue: BookingStore { BookingStore() }
}

extension EnvironmentValues {
    var bookingStore: BookingStore {
        get { self[BookingStoreKey.self] }
        set { self[BookingStoreKey.self] = newValue }
    }
}

extension View {
    func bookingStore(_ store: BookingStore) -> some View {
        environment(\.bookingStore, store)
    }
}
