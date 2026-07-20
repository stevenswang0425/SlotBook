//
//  BookingsViewModel.swift
//  SlotBook
//
//  My Bookings tab: segments, detail navigation hooks, cancel + store sync.
//
//  Cancel path:
//    requestCancel → confirmation alert → confirmCancel
//    → BookingStore.cancelCourtBooking / cancel (optimistic)
//    → reservationEpoch bumps → ClubDetail reloads availability
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
    /// Marketplace booking pending cancel.
    var bookingPendingCancel: Booking?
    /// Court booking pending cancel.
    var courtBookingPendingCancel: CourtBooking?
    var toastMessage: String?
    var toastIsError: Bool = false
    var isCancelling: Bool = false
    var isRefreshing: Bool = false
    /// Wall clock for upcoming / past split (refreshed on appear & pull).
    var now: Date = Date()

    init(store: BookingStore) {
        self.store = store
    }

    // MARK: - Derived lists

    var displayedCourtBookings: [CourtBooking] {
        switch selectedSegment {
        case .upcoming: return store.upcomingCourtBookings(now: now)
        case .past: return store.pastCourtBookings(now: now)
        }
    }

    var displayedBookings: [Booking] {
        switch selectedSegment {
        case .upcoming: return store.upcomingBookings(now: now)
        case .past: return store.pastBookings(now: now)
        }
    }

    var isEmpty: Bool {
        displayedCourtBookings.isEmpty && displayedBookings.isEmpty
    }

    var upcomingCount: Int {
        store.upcomingCourtBookings(now: now).count + store.upcomingBookings(now: now).count
    }

    var pastCount: Int {
        store.pastCourtBookings(now: now).count + store.pastBookings(now: now).count
    }

    var showsCancelConfirmation: Bool {
        get { bookingPendingCancel != nil || courtBookingPendingCancel != nil }
        set {
            if !newValue {
                bookingPendingCancel = nil
                courtBookingPendingCancel = nil
            }
        }
    }

    var cancelAlertTitle: String { "Cancel booking?" }

    var cancelAlertMessage: String {
        if let court = courtBookingPendingCancel {
            let name = court.clubName ?? "Court booking"
            return "\(name) on \(court.dateTimeLabel()) will be cancelled. Free cancellation up to 2 hours before start — your court time will open for others."
        }
        if let booking = bookingPendingCancel {
            return "\(booking.item.name) on \(booking.dateTimeLabel()) will be cancelled and the time slot will become available again."
        }
        return "This reservation will be cancelled."
    }

    // MARK: - Live lookup (detail screens)

    func courtBooking(id: UUID) -> CourtBooking? {
        store.courtBooking(withID: id)
    }

    func marketplaceBooking(id: UUID) -> Booking? {
        store.booking(withID: id)
    }

    // MARK: - Segment

    func selectSegment(_ segment: BookingsSegment) {
        guard selectedSegment != segment else { return }
        selectedSegment = segment
        HapticFeedback.selection()
    }

    // MARK: - Cancel

    func requestCancel(_ booking: Booking) {
        guard booking.isUpcoming(now: now) else { return }
        courtBookingPendingCancel = nil
        bookingPendingCancel = booking
        HapticFeedback.lightImpact()
    }

    func requestCancelCourt(_ booking: CourtBooking) {
        guard booking.isUpcoming(now: now) else { return }
        bookingPendingCancel = nil
        courtBookingPendingCancel = booking
        HapticFeedback.lightImpact()
    }

    func dismissCancelConfirmation() {
        bookingPendingCancel = nil
        courtBookingPendingCancel = nil
    }

    /// Optimistic cancel → BookingStore → epoch bump (Club Detail listens).
    @discardableResult
    func confirmCancel() async -> Bool {
        isCancelling = true
        // Calm simulated latency (repository seam for future Supabase cancel).
        try? await Task.sleep(for: .milliseconds(420))

        if let court = courtBookingPendingCancel {
            let cancelled = store.cancelCourtBooking(id: court.id, at: Date())
            courtBookingPendingCancel = nil
            isCancelling = false
            if cancelled != nil {
                presentToast("Booking cancelled · court released", isError: false)
                HapticFeedback.success()
                refreshClock()
                return true
            } else {
                presentToast("Couldn't cancel this booking. Please try again.", isError: true)
                HapticFeedback.error()
                return false
            }
        }

        guard let booking = bookingPendingCancel else {
            isCancelling = false
            return false
        }

        let cancelled = store.cancel(id: booking.id, at: Date())
        bookingPendingCancel = nil
        isCancelling = false

        if cancelled != nil {
            presentToast("Booking cancelled · slot released", isError: false)
            HapticFeedback.success()
            refreshClock()
            return true
        } else {
            presentToast("Couldn't cancel this booking. Please try again.", isError: true)
            HapticFeedback.error()
            return false
        }
    }

    // MARK: - Toast / refresh

    func dismissToast() {
        toastMessage = nil
    }

    func refreshClock() {
        now = Date()
    }

    /// Pull-to-refresh: re-evaluate upcoming/past boundary.
    func refresh() async {
        isRefreshing = true
        try? await Task.sleep(for: .milliseconds(500))
        refreshClock()
        isRefreshing = false
    }

    private func presentToast(_ message: String, isError: Bool) {
        toastIsError = isError
        toastMessage = message
        scheduleToastDismiss()
    }

    private func scheduleToastDismiss() {
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.6))
            guard !Task.isCancelled else { return }
            self?.toastMessage = nil
        }
    }
}
