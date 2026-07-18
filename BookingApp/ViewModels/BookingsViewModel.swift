//
//  BookingsViewModel.swift
//  SlotBook
//
//  My Bookings tab: segments, cancel flow, toast feedback, pull-to-refresh.
//

import Foundation
import Observation

enum BookingsSegment: String, CaseIterable, Identifiable, Sendable {
    case upcoming
    case past

    var id: String { rawValue }

    var title: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .past: return "Past"
        }
    }
}

@Observable
@MainActor
final class BookingsViewModel {

    private let store: BookingStore

    var selectedSegment: BookingsSegment = .upcoming
    var bookingPendingCancel: Booking?
    var toastMessage: String?
    var toastIsError: Bool = false
    var isCancelling: Bool = false
    var isRefreshing: Bool = false
    var now: Date = Date()

    init(store: BookingStore) {
        self.store = store
    }

    // MARK: - Derived

    var displayedBookings: [Booking] {
        switch selectedSegment {
        case .upcoming: return store.upcomingBookings(now: now)
        case .past: return store.pastBookings(now: now)
        }
    }

    var isEmpty: Bool { displayedBookings.isEmpty }

    var upcomingCount: Int { store.upcomingBookings(now: now).count }

    var pastCount: Int { store.pastBookings(now: now).count }

    var showsCancelConfirmation: Bool {
        get { bookingPendingCancel != nil }
        set { if !newValue { bookingPendingCancel = nil } }
    }

    // MARK: - Intentions

    func selectSegment(_ segment: BookingsSegment) {
        guard selectedSegment != segment else { return }
        selectedSegment = segment
        HapticFeedback.selection()
    }

    func requestCancel(_ booking: Booking) {
        guard booking.isUpcoming(now: now) else { return }
        bookingPendingCancel = booking
        HapticFeedback.lightImpact()
    }

    func dismissCancelConfirmation() {
        bookingPendingCancel = nil
    }

    func confirmCancel() async {
        guard let booking = bookingPendingCancel else { return }
        isCancelling = true

        try? await Task.sleep(for: .milliseconds(450))

        let cancelled = store.cancel(id: booking.id, at: Date())
        bookingPendingCancel = nil
        isCancelling = false

        if cancelled != nil {
            toastIsError = false
            toastMessage = "Booking cancelled · slot released"
            HapticFeedback.success()
            scheduleToastDismiss()
            refreshClock()
        } else {
            toastIsError = true
            toastMessage = "Couldn't cancel this booking. Please try again."
            HapticFeedback.error()
            scheduleToastDismiss()
        }
    }

    func dismissToast() {
        toastMessage = nil
    }

    func refreshClock() {
        now = Date()
    }

    /// Pull-to-refresh: re-evaluate upcoming/past boundary with a calm delay.
    func refresh() async {
        isRefreshing = true
        try? await Task.sleep(for: .milliseconds(500))
        refreshClock()
        isRefreshing = false
    }

    // MARK: - Private

    private func scheduleToastDismiss() {
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.6))
            guard !Task.isCancelled else { return }
            self?.toastMessage = nil
        }
    }
}
