//
//  AdminClubModels.swift
//  SlotBook
//
//  Owner/admin models for badminton clubs & courts.
//  Court numbers are visible here only — never on customer surfaces.
//

import Foundation

// MARK: - Managed club (editable admin copy)

/// Mutable club record for owner tools (maps from/to `BadmintonClub`).
nonisolated struct AdminManagedClub: Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var description: String
    var imageName: String
    var address: String
    var city: String
    var primaryColor: ItemColor
    var tagline: String
    var amenities: [String]
    var pricePerHourCAD: Int
    var isIndoor: Bool
    var hasCoaching: Bool
    var openingHours: String

    var locationLabel: String { "\(address), \(city)" }

    var priceLabel: String { "$\(pricePerHourCAD)/hr" }

    func toBadmintonClub(totalCourts: Int) -> BadmintonClub {
        BadmintonClub(
            id: id,
            name: name,
            description: description,
            imageName: imageName,
            address: address,
            city: city,
            totalCourts: totalCourts,
            primaryColor: primaryColor,
            tagline: tagline,
            amenities: amenities,
            pricePerHourCAD: pricePerHourCAD,
            isIndoor: isIndoor,
            hasCoaching: hasCoaching,
            openingHours: openingHours
        )
    }

    static func from(_ club: BadmintonClub) -> AdminManagedClub {
        AdminManagedClub(
            id: club.id,
            name: club.name,
            description: club.description,
            imageName: club.imageName,
            address: club.address,
            city: club.city,
            primaryColor: club.primaryColor,
            tagline: club.tagline,
            amenities: club.amenities,
            pricePerHourCAD: club.pricePerHourCAD,
            isIndoor: club.isIndoor,
            hasCoaching: club.hasCoaching,
            openingHours: club.openingHours
        )
    }
}

// MARK: - Managed court (admin-visible inventory)

nonisolated struct AdminManagedCourt: Identifiable, Hashable, Sendable {
    var id: UUID
    var clubId: UUID
    var courtNumber: Int
    var isActive: Bool

    var displayName: String { "Court \(courtNumber)" }

    func toCourt() -> Court {
        Court(id: id, clubId: clubId, courtNumber: courtNumber, isActive: isActive)
    }

    static func from(_ court: Court) -> AdminManagedCourt {
        AdminManagedCourt(
            id: court.id,
            clubId: court.clubId,
            courtNumber: court.courtNumber,
            isActive: court.isActive
        )
    }
}

// MARK: - Utilization snapshot

/// Fill metrics for admin club cards (mock-friendly).
nonisolated struct ClubUtilization: Hashable, Sendable {
    /// 0…1 fraction of capacity used today.
    var today: Double
    /// 0…1 fraction of capacity used this week.
    var week: Double
    var todayBookingCount: Int
    var weekBookingCount: Int

    var todayPercentLabel: String {
        "\(Int((today * 100).rounded()))%"
    }

    var weekPercentLabel: String {
        "\(Int((week * 100).rounded()))%"
    }

    static let zero = ClubUtilization(today: 0, week: 0, todayBookingCount: 0, weekBookingCount: 0)
}

// MARK: - Admin court booking row

/// Owner-facing booking (shows court number + guest PII).
nonisolated struct AdminCourtBookingRow: Identifiable, Hashable, Sendable {
    let id: UUID
    let clubId: UUID
    let clubName: String
    let courtId: UUID
    let courtNumber: Int
    let customerName: String
    let customerPhone: String
    let start: Date
    let end: Date
    let durationMinutes: Int
    var status: BookingStatus
    let referenceCode: String
    let isGuest: Bool

    var durationLabel: String {
        if durationMinutes >= 60, durationMinutes % 60 == 0 {
            let h = durationMinutes / 60
            return h == 1 ? "1 hr" : "\(h) hr"
        }
        return "\(durationMinutes) min"
    }

    func rangeLabel(locale: Locale = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.timeStyle = .short
        f.dateStyle = .none
        return "\(f.string(from: start)) – \(f.string(from: end))"
    }

    func dateTimeLabel(locale: Locale = .current) -> String {
        let d = DateFormatter()
        d.locale = locale
        d.setLocalizedDateFormatFromTemplate("MMMdEEE")
        return "\(d.string(from: start)) · \(rangeLabel(locale: locale))"
    }

    static func from(_ booking: CourtBooking, isGuest: Bool = true) -> AdminCourtBookingRow {
        AdminCourtBookingRow(
            id: booking.id,
            clubId: booking.clubId,
            clubName: booking.clubName ?? "Club",
            courtId: booking.courtId,
            courtNumber: booking.courtNumber ?? 0,
            customerName: booking.name,
            customerPhone: booking.phoneDisplay,
            start: booking.start,
            end: booking.end,
            durationMinutes: booking.durationMinutes,
            status: booking.status,
            referenceCode: booking.referenceCode,
            isGuest: isGuest
        )
    }
}
