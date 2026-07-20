//
//  BadmintonModels.swift
//  SlotBook
//
//  Core domain models for the badminton court booking variation.
//  Kept nonisolated for Swift 6 default MainActor isolation compatibility.
//
//  Note: CourtBooking / CourtTimeSlot avoid clashing with marketplace
//  `Booking` and `TimeSlot` types already in the module.
//

import Foundation

// MARK: - Discovery filter

/// Horizontal filter chips on Discover (mock-backed attributes on clubs).
nonisolated enum ClubDiscoveryFilter: String, CaseIterable, Identifiable, Sendable, Hashable {
    case all
    case indoor
    case withCoaching

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "All"
        case .indoor: return "Indoor"
        case .withCoaching: return "With Coaching"
        }
    }

    var systemImage: String? {
        switch self {
        case .all: return "square.grid.2x2"
        case .indoor: return "building.2"
        case .withCoaching: return "figure.badminton"
        }
    }
}

// MARK: - Club

/// A badminton club / venue the player can discover and book.
nonisolated struct BadmintonClub: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let description: String
    /// SF Symbol used as placeholder hero art until real photos land.
    let imageName: String
    let address: String
    let city: String
    /// Total courts at this club (product surface).
    let totalCourts: Int
    /// Brand primary as 0…1 sRGB (drives ThemeManager club override).
    let primaryColor: ItemColor
    /// Optional short tagline for cards.
    let tagline: String
    /// Amenities shown on detail (e.g. parking, pro shop).
    let amenities: [String]
    /// Hourly rate in CAD major units (display-only until payments).
    let pricePerHourCAD: Int
    /// Indoor courts (filter chip).
    let isIndoor: Bool
    /// Offers coaching programs (filter chip).
    let hasCoaching: Bool
    /// Human-readable opening hours for the stats row.
    let openingHours: String

    var courtsLabel: String {
        totalCourts == 1 ? "1 court" : "\(totalCourts) courts"
    }

    var priceLabel: String {
        "$\(pricePerHourCAD)/hr"
    }

    var locationLabel: String {
        "\(address), \(city)"
    }

    /// One-line address suitable for cards.
    var shortAddressLabel: String {
        "\(address) · \(city)"
    }

    /// Short blurb for card body (first sentence-ish, capped).
    var cardSummary: String {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if let period = trimmed.firstIndex(of: ".") {
            let sentence = String(trimmed[...period])
            return sentence.count > 8 ? sentence : trimmed
        }
        return trimmed
    }

    func matches(filter: ClubDiscoveryFilter) -> Bool {
        switch filter {
        case .all: return true
        case .indoor: return isIndoor
        case .withCoaching: return hasCoaching
        }
    }
}

// MARK: - Court (hidden inventory unit)

/// Physical court inside a club — not listed as a product; used for inventory.
nonisolated struct Court: Identifiable, Hashable, Sendable {
    let id: UUID
    let clubId: UUID
    /// 1-based court number shown to owners / on booking confirm later.
    let courtNumber: Int
    let isActive: Bool

    var displayName: String {
        "Court \(courtNumber)"
    }
}

// MARK: - Booking duration

/// Supported play lengths for badminton court booking.
nonisolated enum CourtBookingDuration: Int, CaseIterable, Identifiable, Sendable, Hashable {
    case fortyFive = 45
    case sixty = 60
    case ninety = 90

    var id: Int { rawValue }

    var minutes: Int { rawValue }

    var label: String {
        "\(rawValue) min"
    }

    var accessibilityLabel: String {
        "\(rawValue) minutes"
    }
}

// MARK: - Court busy interval (internal)

/// A reserved block on a specific court. Never shown with court numbers in UI.
nonisolated struct CourtBusyInterval: Hashable, Sendable {
    let courtId: UUID
    let start: Date
    let end: Date

    func overlaps(_ otherStart: Date, _ otherEnd: Date) -> Bool {
        start < otherEnd && end > otherStart
    }
}

// MARK: - Public start option (court-agnostic UI)

/// A start time the player can book for a chosen duration.
///
/// Availability means **at least one** hidden court is free for the full block.
/// `assignedCourtId` is internal auto-assignment only — never render it.
nonisolated struct ClubStartOption: Identifiable, Hashable, Sendable {
    let id: UUID
    let clubId: UUID
    let start: Date
    let end: Date
    let durationMinutes: Int
    let isAvailable: Bool
    /// First free court for this block (system auto-assign). Do not show in UI.
    let assignedCourtId: UUID?

    var isBooked: Bool { !isAvailable }

    /// Compact range, e.g. "9:00 – 9:45 AM".
    func rangeLabel(locale: Locale = .current) -> String {
        let formatter = Self.timeFormatter(locale: locale)
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }

    func startLabel(locale: Locale = .current) -> String {
        Self.timeFormatter(locale: locale).string(from: start)
    }

    func endLabel(locale: Locale = .current) -> String {
        Self.timeFormatter(locale: locale).string(from: end)
    }

    private static func timeFormatter(locale: Locale) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }
}

// MARK: - Time slot (per-court inventory unit)

/// A bookable window on a specific court (inventory layer, not player-facing).
nonisolated struct CourtTimeSlot: Identifiable, Hashable, Sendable {
    let id: UUID
    let clubId: UUID
    let courtId: UUID
    let start: Date
    let end: Date
    var isAvailable: Bool

    var durationMinutes: Int {
        Int(end.timeIntervalSince(start) / 60)
    }
}

// MARK: - Draft selection (Iteration 3 → 4 handoff)

/// Pending court booking after the player picks a slot (before guest details).
nonisolated struct CourtBookingDraft: Identifiable, Hashable, Sendable {
    let id: UUID
    let club: BadmintonClub
    let option: ClubStartOption
    /// Calendar day (start-of-day).
    let date: Date

    var durationMinutes: Int { option.durationMinutes }

    /// Rough price from club hourly rate (display only).
    var estimatedPriceCAD: Int {
        let hours = Double(option.durationMinutes) / 60.0
        return Int((Double(club.pricePerHourCAD) * hours).rounded())
    }

    var estimatedPriceLabel: String {
        "$\(estimatedPriceCAD)"
    }

    init(club: BadmintonClub, option: ClubStartOption, date: Date) {
        self.id = option.id
        self.club = club
        self.option = option
        self.date = date
    }
}

// MARK: - Create request

/// Payload to create a court booking (maps cleanly to a future Supabase insert).
nonisolated struct CourtBookingCreateRequest: Sendable {
    let clubId: UUID
    let clubName: String
    let slotId: UUID
    let start: Date
    let end: Date
    let durationMinutes: Int
    let guestName: String
    /// Digits-only phone.
    let phoneDigits: String
    let email: String?
    /// Busy intervals already known to the client (live store + mock).
    let additionalBusy: [CourtBusyInterval]
}

// MARK: - Booking (court reservation)

/// A court booking — guest or signed-in player.
///
/// FUTURE SUPABASE: maps to `bookings` with clubId/store_id + court/resource id.
/// Court number is stored for inventory but **never** shown in player UI.
nonisolated struct CourtBooking: Identifiable, Hashable, Sendable {
    let id: UUID
    let clubId: UUID
    let courtId: UUID
    let slotId: UUID
    /// Duration of the reserved block.
    let durationMinutes: Int
    let start: Date
    let end: Date
    /// Guest / player name.
    let name: String
    /// Digits-only phone for storage / display reformatting.
    let phoneDigits: String
    let email: String?
    let referenceCode: String
    let createdAt: Date
    var status: BookingStatus
    var cancelledAt: Date?

    var clubName: String?
    /// Owner/admin only — never show to players in public booking UI.
    var courtNumber: Int?

    // MARK: Display helpers (player-safe — no court numbers)

    var phoneDisplay: String {
        PhoneNumberFormatter.display(fromDigits: phoneDigits)
    }

    var durationLabel: String {
        if durationMinutes >= 60, durationMinutes % 60 == 0 {
            let hours = durationMinutes / 60
            return hours == 1 ? "1 hr" : "\(hours) hr"
        }
        return "\(durationMinutes) min"
    }

    func rangeLabel(locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }

    func dateLabel(locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: start)
    }

    func dateTimeLabel(locale: Locale = .current) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.setLocalizedDateFormatFromTemplate("MMMdEEE")
        return "\(dateFormatter.string(from: start)) · \(rangeLabel(locale: locale))"
    }

    func displayStatus(now: Date = Date()) -> BookingDisplayStatus {
        switch status {
        case .cancelled:
            return .cancelled
        case .confirmed:
            return end > now ? .upcoming : .completed
        }
    }

    func isUpcoming(now: Date = Date()) -> Bool {
        displayStatus(now: now) == .upcoming
    }

    func isPast(now: Date = Date()) -> Bool {
        !isUpcoming(now: now)
    }
}

// MARK: - Factory

extension CourtBooking {
    static func make(
        clubId: UUID,
        clubName: String,
        courtId: UUID,
        courtNumber: Int?,
        slotId: UUID,
        start: Date,
        end: Date,
        durationMinutes: Int,
        guestName: String,
        phoneDigits: String,
        email: String? = nil,
        createdAt: Date = Date(),
        status: BookingStatus = .confirmed,
        cancelledAt: Date? = nil
    ) -> CourtBooking {
        CourtBooking(
            id: UUID(),
            clubId: clubId,
            courtId: courtId,
            slotId: slotId,
            durationMinutes: durationMinutes,
            start: start,
            end: end,
            name: guestName,
            phoneDigits: phoneDigits,
            email: email,
            referenceCode: generateReferenceCode(),
            createdAt: createdAt,
            status: status,
            cancelledAt: cancelledAt,
            clubName: clubName,
            courtNumber: courtNumber
        )
    }

    /// Compact reference like `CB-7F3A91` (court booking).
    private static func generateReferenceCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let suffix = (0..<6).map { _ in alphabet.randomElement()! }
        return "CB-" + String(suffix)
    }
}

// MARK: - Repository errors

enum CourtBookingError: LocalizedError, Equatable, Sendable {
    case slotUnavailable
    case network
    case invalidGuest
    case unknown

    var errorDescription: String? {
        switch self {
        case .slotUnavailable:
            return "This time was just taken. Please pick another slot."
        case .network:
            return "We couldn't reach the server. Check your connection and try again."
        case .invalidGuest:
            return "Please check your name and phone number."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}
