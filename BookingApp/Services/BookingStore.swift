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

    /// Confirmed badminton court bookings (Iteration 3+).
    private(set) var courtBookings: [CourtBooking] = []

    /// Pending court selection after review sheet (guest form lands in Iteration 4).
    private(set) var pendingCourtDraft: CourtBookingDraft?

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

    var isEmpty: Bool { bookings.isEmpty && courtBookings.isEmpty }

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

    // MARK: - Court bookings (badminton)

    func upcomingCourtBookings(now: Date = Date()) -> [CourtBooking] {
        courtBookings
            .filter { $0.isUpcoming(now: now) }
            .sorted { $0.start < $1.start }
    }

    func pastCourtBookings(now: Date = Date()) -> [CourtBooking] {
        courtBookings
            .filter { $0.isPast(now: now) }
            .sorted { $0.start > $1.start }
    }

    func courtBooking(withID id: UUID) -> CourtBooking? {
        courtBookings.first { $0.id == id }
    }

    /// Busy intervals from confirmed court bookings for a club/day (hidden courts).
    func courtBusyIntervals(
        clubId: UUID,
        on day: Date,
        calendar: Calendar = .current
    ) -> [CourtBusyInterval] {
        let dayStart = calendar.startOfDay(for: day)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return []
        }
        return courtBookings.compactMap { booking in
            guard booking.status == .confirmed,
                  booking.clubId == clubId,
                  booking.start >= dayStart,
                  booking.start < dayEnd
            else { return nil }
            return CourtBusyInterval(
                courtId: booking.courtId,
                start: booking.start,
                end: booking.end
            )
        }
    }

    /// Pending draft while the booking sheet is open (deep-link / recovery prep).
    func setPendingCourtDraft(_ draft: CourtBookingDraft?) {
        pendingCourtDraft = draft
        bumpEpoch()
    }

    func addCourtBooking(_ booking: CourtBooking) {
        if courtBookings.contains(where: { $0.id == booking.id }) { return }
        courtBookings.insert(booking, at: 0)
        pendingCourtDraft = nil
        bumpEpoch()
        publishNotice(
            SlotAvailabilityNotice(
                kind: .taken,
                slotID: booking.slotId,
                itemID: booking.clubId,
                source: .localBooking,
                message: "Court reserved · \(booking.referenceCode)"
            )
        )
    }

    @discardableResult
    func cancelCourtBooking(id: UUID, at date: Date = Date()) -> CourtBooking? {
        guard let index = courtBookings.firstIndex(where: { $0.id == id }) else { return nil }
        guard courtBookings[index].status == .confirmed else { return nil }
        courtBookings[index].status = .cancelled
        courtBookings[index].cancelledAt = date
        bumpEpoch()
        publishNotice(
            SlotAvailabilityNotice(
                kind: .freed,
                slotID: courtBookings[index].slotId,
                itemID: courtBookings[index].clubId,
                source: .localCancel,
                message: "Court booking cancelled"
            )
        )
        return courtBookings[index]
    }

    func clearAll() {
        bookings.removeAll()
        courtBookings.removeAll()
        pendingCourtDraft = nil
        reservedSlotIDs.removeAll()
        remoteReservedSlotIDs.removeAll()
        remoteSlotItemIDs.removeAll()
        lastNotice = nil
        bumpEpoch()
    }

    // MARK: - Preview seed

    /// Seeds badminton court bookings for My Bookings previews / demos.
    func seedCourtPreviewData(now: Date = Date(), calendar: Calendar = .current) {
        clearAll()

        // Upcoming — tomorrow morning at Toronto.
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
            let day = calendar.startOfDay(for: tomorrow)
            if let start = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: day),
               let end = calendar.date(byAdding: .minute, value: 60, to: start) {
                let courts = MockData.courts(for: MockData.torontoClubId)
                addCourtBooking(
                    CourtBooking.make(
                        clubId: MockData.torontoClubId,
                        clubName: "Toronto Badminton Club",
                        courtId: courts.first?.id ?? UUID(),
                        courtNumber: courts.first?.courtNumber,
                        slotId: UUID(),
                        start: start,
                        end: end,
                        durationMinutes: 60,
                        guestName: "Alex Rivera",
                        phoneDigits: "5551234567",
                        createdAt: now
                    )
                )
            }
        }

        // Upcoming — day after at Willowdale (90 min).
        if let day2 = calendar.date(byAdding: .day, value: 2, to: now) {
            let day = calendar.startOfDay(for: day2)
            if let start = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: day),
               let end = calendar.date(byAdding: .minute, value: 90, to: start) {
                let courts = MockData.courts(for: MockData.willowdaleClubId)
                addCourtBooking(
                    CourtBooking.make(
                        clubId: MockData.willowdaleClubId,
                        clubName: "Willowdale Badminton Centre",
                        courtId: courts.first?.id ?? UUID(),
                        courtNumber: courts.first?.courtNumber,
                        slotId: UUID(),
                        start: start,
                        end: end,
                        durationMinutes: 90,
                        guestName: "Alex Rivera",
                        phoneDigits: "5551234567",
                        createdAt: now
                    )
                )
            }
        }

        // Past completed — yesterday at North York.
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now) {
            let day = calendar.startOfDay(for: yesterday)
            if let start = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: day),
               let end = calendar.date(byAdding: .minute, value: 45, to: start) {
                let courts = MockData.courts(for: MockData.northYorkClubId)
                addCourtBooking(
                    CourtBooking.make(
                        clubId: MockData.northYorkClubId,
                        clubName: "North York Badminton Arena",
                        courtId: courts.first?.id ?? UUID(),
                        courtNumber: courts.first?.courtNumber,
                        slotId: UUID(),
                        start: start,
                        end: end,
                        durationMinutes: 45,
                        guestName: "Alex Rivera",
                        phoneDigits: "5551234567",
                        createdAt: yesterday
                    )
                )
            }
        }

        // Past cancelled — two days ago.
        if let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now) {
            let day = calendar.startOfDay(for: twoDaysAgo)
            if let start = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: day),
               let end = calendar.date(byAdding: .minute, value: 60, to: start) {
                let courts = MockData.courts(for: MockData.torontoClubId)
                let booking = CourtBooking.make(
                    clubId: MockData.torontoClubId,
                    clubName: "Toronto Badminton Club",
                    courtId: courts.dropFirst().first?.id ?? UUID(),
                    courtNumber: courts.dropFirst().first?.courtNumber,
                    slotId: UUID(),
                    start: start,
                    end: end,
                    durationMinutes: 60,
                    guestName: "Alex Rivera",
                    phoneDigits: "5551234567",
                    createdAt: twoDaysAgo,
                    status: .cancelled,
                    cancelledAt: twoDaysAgo
                )
                // Insert cancelled without going through add's confirmed path.
                courtBookings.insert(booking, at: courtBookings.count)
                bumpEpoch()
            }
        }
    }

    func seedPreviewData(now: Date = Date(), calendar: Calendar = .current) {
        clearAll()
        // Prefer court bookings for badminton MVP previews.
        seedCourtPreviewData(now: now, calendar: calendar)

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
