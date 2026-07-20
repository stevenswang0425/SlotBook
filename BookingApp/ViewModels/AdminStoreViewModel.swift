//
//  AdminStoreViewModel.swift
//  SlotBook
//
//  Owner “My Store” hub for badminton clubs: list, utilization, bookings.
//  Mock-backed via AdminClubRepository + BookingStore.
//

import Foundation
import Observation

@Observable
@MainActor
final class AdminStoreViewModel {

    // MARK: - State

    private(set) var clubs: [AdminManagedClub] = []
    private(set) var courtsByClub: [UUID: [AdminManagedCourt]] = [:]
    private(set) var isLoading = false
    var loadError: String?

    /// Club filter for unified bookings list (`nil` = all clubs).
    var bookingsClubFilter: UUID?
    var bookingsSegment: BookingsSegment = .upcoming

    private(set) var now: Date = Date()

    // MARK: - Dependencies

    private let adminRepository: any AdminClubRepository
    private weak var bookingStore: BookingStore?
    private let calendar: Calendar

    /// ~open hours for utilization capacity (matches engine 9–22).
    private let openHoursPerDay: Double = 13

    init(
        adminRepository: any AdminClubRepository = MockAdminClubRepository.shared,
        calendar: Calendar = .current
    ) {
        self.adminRepository = adminRepository
        self.calendar = calendar
    }

    func attach(store: BookingStore) {
        bookingStore = store
        // Seed demo court bookings if owner opens admin with empty store.
        if store.courtBookings.isEmpty {
            store.seedCourtPreviewData()
        }
    }

    // MARK: - Derived

    func courts(for clubId: UUID) -> [AdminManagedCourt] {
        courtsByClub[clubId] ?? []
    }

    func activeCourtCount(for clubId: UUID) -> Int {
        courts(for: clubId).filter(\.isActive).count
    }

    func totalCourtCount(for clubId: UUID) -> Int {
        courts(for: clubId).count
    }

    func utilization(for clubId: UUID) -> ClubUtilization {
        guard let store = bookingStore else { return .zero }
        let active = max(activeCourtCount(for: clubId), 1)
        let dayStart = calendar.startOfDay(for: now)
        let weekStart = Self.startOfWeek(for: now, calendar: calendar)
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now

        let clubBookings = store.courtBookings.filter {
            $0.clubId == clubId && $0.status == .confirmed
        }

        let today = clubBookings.filter { calendar.isDate($0.start, inSameDayAs: dayStart) }
        let week = clubBookings.filter { $0.start >= weekStart && $0.start < weekEnd }

        let todayMinutes = today.reduce(0) { $0 + $1.durationMinutes }
        let weekMinutes = week.reduce(0) { $0 + $1.durationMinutes }

        let todayCapacity = Double(active) * openHoursPerDay * 60
        let weekCapacity = todayCapacity * 7

        return ClubUtilization(
            today: min(1, Double(todayMinutes) / max(todayCapacity, 1)),
            week: min(1, Double(weekMinutes) / max(weekCapacity, 1)),
            todayBookingCount: today.count,
            weekBookingCount: week.count
        )
    }

    var allAdminBookings: [AdminCourtBookingRow] {
        guard let store = bookingStore else { return [] }
        var rows = store.courtBookings.map {
            AdminCourtBookingRow.from($0, isGuest: true)
        }
        if let filter = bookingsClubFilter {
            rows = rows.filter { $0.clubId == filter }
        }
        return rows
    }

    var displayedAdminBookings: [AdminCourtBookingRow] {
        let rows = allAdminBookings
        switch bookingsSegment {
        case .upcoming:
            return rows
                .filter { $0.status == .confirmed && $0.end > now }
                .sorted { $0.start < $1.start }
        case .past:
            return rows
                .filter { $0.status != .confirmed || $0.end <= now }
                .sorted { $0.start > $1.start }
        }
    }

    var clubFilterOptions: [(id: UUID?, name: String)] {
        [(nil, "All clubs")] + clubs.map { ($0.id as UUID?, $0.name) }
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        loadError = nil
        now = Date()
        do {
            clubs = try await adminRepository.fetchManagedClubs()
            var map: [UUID: [AdminManagedCourt]] = [:]
            for club in clubs {
                map[club.id] = try await adminRepository.fetchManagedCourts(clubId: club.id)
            }
            courtsByClub = map
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    func refresh() async {
        now = Date()
        await load()
    }

    // MARK: - Bookings

    func selectBookingsFilter(_ clubId: UUID?) {
        bookingsClubFilter = clubId
        HapticFeedback.selection()
    }

    func selectBookingsSegment(_ segment: BookingsSegment) {
        guard bookingsSegment != segment else { return }
        bookingsSegment = segment
        HapticFeedback.selection()
    }

    @discardableResult
    func cancelCourtBooking(id: UUID) -> Bool {
        guard let store = bookingStore else { return false }
        let result = store.cancelCourtBooking(id: id, at: Date())
        if result != nil {
            now = Date()
            HapticFeedback.success()
            return true
        }
        HapticFeedback.error()
        return false
    }

    // MARK: - Private

    nonisolated private static func startOfWeek(for date: Date, calendar: Calendar) -> Date {
        var cal = calendar
        cal.firstWeekday = 2
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: components).map { cal.startOfDay(for: $0) }
            ?? cal.startOfDay(for: date)
    }
}
