//
//  MockAdminData.swift
//  SlotBook
//
//  Deterministic mock inventory + bookings for Admin Mode.
//  Swap for Supabase queries in AdminStoreViewModel later.
//

import Foundation

enum MockAdminData {
    /// Services owned by the demo store (subset of public catalog).
    nonisolated static let services: [AdminService] = [
        AdminService(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01")!,
            name: "Pour-Over Flight",
            description: "Three single-origin pour-overs with tasting notes.",
            imageName: "cup.and.saucer.fill",
            category: .cafe,
            color: ItemColor(r: 180, g: 120, b: 72),
            durationMinutes: 45
        ),
        AdminService(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa02")!,
            name: "Morning Flow Yoga",
            description: "Gentle vinyasa — all levels.",
            imageName: "figure.yoga",
            category: .wellness,
            color: ItemColor(r: 72, g: 160, b: 132),
            durationMinutes: 60
        ),
        AdminService(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa03")!,
            name: "Device Tune-Up",
            description: "Diagnostics and refresh for phones & laptops.",
            imageName: "laptopcomputer.and.iphone",
            category: .service,
            color: ItemColor(r: 70, g: 110, b: 200),
            durationMinutes: 50
        ),
    ]

    private nonisolated static let customers: [(String, String, Bool)] = [
        ("Maya Torres", "(555) 201-8844", true),
        ("Chris Nguyen", "(555) 310-2291", false),
        ("Riley Brooks", "(555) 441-0092", true),
        ("Avery Patel", "(555) 662-1180", false),
        ("Jamie Cole", "(555) 773-4401", true),
    ]

    /// Builds a week of 9–16:30 half-hour slots with ~35% booked.
    nonisolated static func slots(
        for service: AdminService,
        weekStart: Date,
        calendar: Calendar = .current
    ) -> [AdminSlotOccurrence] {
        let startOfWeek = calendar.startOfDay(for: weekStart)
        var results: [AdminSlotOccurrence] = []
        var bookingIndex = 0

        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else {
                continue
            }
            for hour in 9..<17 {
                for minute in [0, 30] {
                    guard
                        let start = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                        let end = calendar.date(byAdding: .minute, value: 30, to: start)
                    else { continue }

                    // Deterministic “random” booking pattern.
                    var hasher = Hasher()
                    hasher.combine(service.id)
                    hasher.combine(start.timeIntervalSinceReferenceDate)
                    let seed = abs(hasher.finalize())
                    let isBooked = seed % 100 < 35

                    let booking: AdminBooking?
                    if isBooked {
                        let customer = customers[bookingIndex % customers.count]
                        bookingIndex += 1
                        booking = AdminBooking(
                            id: UUID(),
                            serviceId: service.id,
                            serviceName: service.name,
                            customerName: customer.0,
                            customerPhone: customer.1,
                            customerEmail: customer.2 ? nil : "\(customer.0.split(separator: " ").first?.lowercased() ?? "guest")@example.com",
                            start: start,
                            end: end,
                            status: .confirmed,
                            referenceCode: "SB-\(String(format: "%04X", seed % 0xFFFF))",
                            isGuest: customer.2
                        )
                    } else {
                        booking = nil
                    }

                    results.append(
                        AdminSlotOccurrence(
                            id: UUID(),
                            serviceId: service.id,
                            start: start,
                            end: end,
                            booking: booking
                        )
                    )
                }
            }
        }
        return results
    }
}
