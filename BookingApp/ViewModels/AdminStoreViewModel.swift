//
//  AdminStoreViewModel.swift
//  SlotBook
//
//  Owner admin: services list, week calendar slots, cancel booking.
//  Mock-backed; swap loaders for Supabase later.
//

import Foundation
import Observation

@Observable
@MainActor
final class AdminStoreViewModel {
    private(set) var services: [AdminService] = []
    private(set) var slotsByService: [UUID: [AdminSlotOccurrence]] = [:]
    private(set) var isLoading = false

    /// Monday (or locale first weekday) of the visible week.
    var weekStart: Date

    private let calendar: Calendar

    init(calendar: Calendar = .current, now: Date = Date()) {
        self.calendar = calendar
        self.weekStart = Self.startOfWeek(for: now, calendar: calendar)
    }

    // MARK: - Derived

    func slots(for serviceId: UUID) -> [AdminSlotOccurrence] {
        slotsByService[serviceId] ?? []
    }

    func slots(for serviceId: UUID, on day: Date) -> [AdminSlotOccurrence] {
        let dayStart = calendar.startOfDay(for: day)
        return slots(for: serviceId).filter {
            calendar.isDate($0.start, inSameDayAs: dayStart)
        }
    }

    func daysInWeek() -> [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    func bookingCount(for serviceId: UUID, on day: Date) -> Int {
        slots(for: serviceId, on: day).filter(\.isBooked).count
    }

    func weekBookingCount(for serviceId: UUID) -> Int {
        slots(for: serviceId).filter(\.isBooked).count
    }

    var weekRangeLabel: String {
        let end = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMMd")
        return "\(f.string(from: weekStart)) – \(f.string(from: end))"
    }

    // MARK: - Intentions

    func load() {
        isLoading = true
        // FUTURE: fetch items where store_id = owner store via Supabase.
        services = MockAdminData.services
        rebuildSlots()
        isLoading = false
    }

    func goToPreviousWeek() {
        if let next = calendar.date(byAdding: .day, value: -7, to: weekStart) {
            weekStart = next
            rebuildSlots()
        }
    }

    func goToNextWeek() {
        if let next = calendar.date(byAdding: .day, value: 7, to: weekStart) {
            weekStart = next
            rebuildSlots()
        }
    }

    func goToThisWeek() {
        weekStart = Self.startOfWeek(for: Date(), calendar: calendar)
        rebuildSlots()
    }

    func cancelBooking(_ booking: AdminBooking) {
        guard var list = slotsByService[booking.serviceId] else { return }
        for i in list.indices {
            if list[i].booking?.id == booking.id {
                list[i].booking = nil // free the slot
            }
        }
        slotsByService[booking.serviceId] = list
        HapticFeedback.success()
    }

    // MARK: - Private

    private func rebuildSlots() {
        var map: [UUID: [AdminSlotOccurrence]] = [:]
        for service in services {
            // FUTURE: load time_slots + bookings for range from API.
            map[service.id] = MockAdminData.slots(for: service, weekStart: weekStart, calendar: calendar)
        }
        slotsByService = map
    }

    nonisolated private static func startOfWeek(for date: Date, calendar: Calendar) -> Date {
        var cal = calendar
        cal.firstWeekday = 2 // Monday
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: components).map { cal.startOfDay(for: $0) }
            ?? cal.startOfDay(for: date)
    }
}
