//
//  ItemDetailViewModel.swift
//  SlotBook
//
//  Item Detail state: dates, slots, booking CTA, and live availability sync.
//

import Foundation
import Observation

/// Snapshot of the slot being booked (survives optimistic “booked” updates).
struct BookingContext: Identifiable, Hashable, Sendable {
    let id: UUID
    let item: Item
    let slot: TimeSlot
    let date: Date

    init(item: Item, slot: TimeSlot, date: Date) {
        self.id = slot.id
        self.item = item
        self.slot = slot
        self.date = date
    }
}

/// View model for the Item Detail & time-slot screen.
@Observable
@MainActor
final class ItemDetailViewModel {

    // MARK: - Item

    let item: Item
    var isFavorite: Bool = false

    // MARK: - Dates

    private(set) var days: [SelectableDay] = []
    var selectedDate: Date

    // MARK: - Slots

    private(set) var slots: [TimeSlot] = []
    var selectedSlotID: UUID?
    var isBookingSheetPresented: Bool = false
    private(set) var bookingContext: BookingContext?

    /// True while the slot grid is rebuilding after a day change / refresh.
    var isLoadingSlots: Bool = false

    /// User-facing error (e.g. failed refresh).
    var loadError: String?

    /// Live toast when a remote user takes a slot on the visible day.
    var liveToastMessage: String?
    var liveToastStyle: LiveToastStyle = .info

    enum LiveToastStyle: Equatable {
        case info
        case warning
        case success
    }

    private var bookingStore: BookingStore?
    /// Slot IDs we already toasted about (avoid spam on re-sync).
    private var toastedRemoteTakes: Set<UUID> = []
    /// Snapshot of reserved IDs for the current day before last sync.
    private var previousReservedOnDay: Set<UUID> = []

    nonisolated(unsafe) private var toastDismissTask: Task<Void, Never>?

    // MARK: - Derived

    var selectedSlot: TimeSlot? {
        guard let selectedSlotID else { return nil }
        return slots.first { $0.id == selectedSlotID && $0.isAvailable }
    }

    var canBook: Bool { selectedSlot != nil }

    var bookingButtonTitle: String {
        if let slot = selectedSlot {
            return "Book \(slot.startLabel())"
        }
        return "Book Selected Slot"
    }

    // MARK: - Init

    init(item: Item, calendar: Calendar = .current, now: Date = Date()) {
        self.item = item
        let startOfToday = calendar.startOfDay(for: now)
        self.selectedDate = startOfToday
        self.days = MockSlots.upcomingDays(count: 14, from: now, calendar: calendar)
        reloadSlots(calendar: calendar, animated: false)
    }

    // MARK: - Lifecycle

    func attach(store: BookingStore) {
        bookingStore = store
        reloadSlots(animated: false)
    }

    func onAppear() {
        reloadSlots(animated: false)
    }

    func onDisappear() {
        toastDismissTask?.cancel()
        toastDismissTask = nil
    }

    /// Called when `BookingStore.reservationEpoch` changes.
    func handleStoreReservationChange() {
        let before = Set(slots.filter(\.isBooked).map(\.id))
        reloadSlots(animated: true)
        let after = Set(slots.filter(\.isBooked).map(\.id))
        announceRemoteTakes(before: before, after: after)
    }

    func syncReservations() {
        handleStoreReservationChange()
    }

    // MARK: - Intentions

    func toggleFavorite() {
        isFavorite.toggle()
        HapticFeedback.lightImpact()
    }

    func selectDate(_ date: Date, calendar: Calendar = .current) {
        let start = calendar.startOfDay(for: date)
        guard start != selectedDate else { return }

        selectedDate = start
        selectedSlotID = nil
        previousReservedOnDay = []
        toastedRemoteTakes.removeAll()
        HapticFeedback.selection()
        reloadSlots(calendar: calendar, animated: true)
    }

    func selectSlot(_ slot: TimeSlot) {
        guard slot.isAvailable else {
            HapticFeedback.warning()
            showToast("That time is no longer available", style: .warning)
            return
        }

        if selectedSlotID == slot.id {
            selectedSlotID = nil
        } else {
            selectedSlotID = slot.id
            HapticFeedback.lightImpact()
        }
    }

    func beginBooking() {
        guard let slot = selectedSlot else { return }
        // Re-check store in case a remote pulse just took it.
        if bookingStore?.isSlotReserved(slot.id) == true {
            HapticFeedback.warning()
            showToast("Someone just booked this slot", style: .warning)
            reloadSlots(animated: true)
            return
        }
        bookingContext = BookingContext(item: item, slot: slot, date: selectedDate)
        isBookingSheetPresented = true
    }

    func dismissBookingSheet() {
        isBookingSheetPresented = false
        bookingContext = nil
    }

    /// Syncs the grid after the shared store records a successful local booking.
    /// (`BookingStore.add` already reserves the slot and posts a notice.)
    func applySuccessfulBooking(slotID: UUID) {
        if let index = slots.firstIndex(where: { $0.id == slotID }) {
            slots[index].availability = .booked
        }
        if selectedSlotID == slotID {
            selectedSlotID = nil
        }
        // Full resync picks up any concurrent remote changes too.
        reloadSlots(animated: true)
    }

    /// Pull-to-refresh on the detail screen.
    func refresh() async {
        isLoadingSlots = true
        loadError = nil
        try? await Task.sleep(for: .milliseconds(400))
        reloadSlots(animated: true)
        isLoadingSlots = false
    }

    func dismissLiveToast() {
        liveToastMessage = nil
    }

    // MARK: - Private

    private func reloadSlots(calendar: Calendar = .current, animated: Bool) {
        var generated = MockSlots.slots(for: selectedDate, itemID: item.id, calendar: calendar)
        let reserved = bookingStore?.reservedSlotIDs ?? []

        for index in generated.indices {
            if reserved.contains(generated[index].id) {
                generated[index].availability = .booked
            }
        }

        // If the user's selection was taken, clear it quietly.
        if let selectedSlotID,
           let match = generated.first(where: { $0.id == selectedSlotID }),
           !match.isAvailable {
            self.selectedSlotID = nil
        } else if let selectedSlotID,
                  generated.first(where: { $0.id == selectedSlotID }) == nil {
            self.selectedSlotID = nil
        }

        slots = generated
        previousReservedOnDay = Set(generated.filter(\.isBooked).map(\.id))
        loadError = nil
    }

    /// Detect newly booked slots on this day caused by remote activity.
    private func announceRemoteTakes(before: Set<UUID>, after: Set<UUID>) {
        let newlyBooked = after.subtracting(before)
        guard !newlyBooked.isEmpty else { return }

        // Only toast for remote sources on the current item.
        guard let notice = bookingStore?.lastNotice,
              notice.itemID == item.id,
              notice.source == .remoteBooking,
              newlyBooked.contains(notice.slotID),
              !toastedRemoteTakes.contains(notice.slotID) else {
            return
        }

        toastedRemoteTakes.insert(notice.slotID)
        HapticFeedback.warning()
        showToast(notice.message, style: .warning)
    }

    private func showToast(_ message: String, style: LiveToastStyle) {
        liveToastStyle = style
        liveToastMessage = message
        toastDismissTask?.cancel()
        toastDismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.8))
            guard !Task.isCancelled else { return }
            self?.liveToastMessage = nil
        }
    }
}
