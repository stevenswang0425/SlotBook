//
//  Booking.swift
//  SlotBook
//
//  Confirmed reservation created by the booking flow.
//

import Foundation

/// Lifecycle of a reservation in the mock store.
nonisolated enum BookingStatus: String, Sendable, Hashable {
    /// Active reservation (may be upcoming or completed based on time).
    case confirmed
    /// User cancelled — slot is released.
    case cancelled
}

/// UI-facing status for list badges.
nonisolated enum BookingDisplayStatus: String, Sendable, Hashable {
    case upcoming
    case completed
    case cancelled

    var title: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

/// A completed booking for an experience + time slot.
nonisolated struct Booking: Identifiable, Hashable, Sendable {
    let id: UUID
    /// Human-friendly reference shown on success / My Bookings, e.g. "SB-A1B2C3".
    let referenceCode: String
    let item: Item
    let slot: TimeSlot
    /// Calendar day of the booking (start-of-day).
    let date: Date
    let guestName: String
    /// Digits-only phone for storage / display reformatting.
    let phoneDigits: String
    let createdAt: Date
    /// Confirmed vs cancelled (completion is derived from wall-clock time).
    var status: BookingStatus
    /// Set when the guest cancels.
    var cancelledAt: Date?

    var durationMinutes: Int { slot.durationMinutes }

    var durationLabel: String {
        let minutes = durationMinutes
        if minutes >= 60, minutes % 60 == 0 {
            let hours = minutes / 60
            return hours == 1 ? "1 hr" : "\(hours) hr"
        }
        return "\(minutes) min"
    }

    /// Formatted phone for UI, e.g. "(555) 123-4567".
    var phoneDisplay: String {
        PhoneNumberFormatter.display(fromDigits: phoneDigits)
    }

    /// Locale-aware full date for summaries.
    func dateLabel(locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Compact date + time line for list cards.
    func dateTimeLabel(locale: Locale = .current) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.setLocalizedDateFormatFromTemplate("MMMdEEE")
        let day = dateFormatter.string(from: date)
        return "\(day) · \(slot.rangeLabel(locale: locale))"
    }

    /// Resolves badge status for lists.
    func displayStatus(now: Date = Date()) -> BookingDisplayStatus {
        switch status {
        case .cancelled:
            return .cancelled
        case .confirmed:
            return slot.end > now ? .upcoming : .completed
        }
    }

    /// True when the booking still appears under Upcoming.
    func isUpcoming(now: Date = Date()) -> Bool {
        displayStatus(now: now) == .upcoming
    }

    /// True when the booking appears under Past (completed or cancelled).
    func isPast(now: Date = Date()) -> Bool {
        !isUpcoming(now: now)
    }
}

// MARK: - Factory

extension Booking {
    /// Builds a booking with a generated reference code.
    static func make(
        item: Item,
        slot: TimeSlot,
        date: Date,
        guestName: String,
        phoneDigits: String,
        createdAt: Date = Date(),
        status: BookingStatus = .confirmed,
        cancelledAt: Date? = nil
    ) -> Booking {
        Booking(
            id: UUID(),
            referenceCode: generateReferenceCode(),
            item: item,
            slot: slot,
            date: date,
            guestName: guestName,
            phoneDigits: phoneDigits,
            createdAt: createdAt,
            status: status,
            cancelledAt: cancelledAt
        )
    }

    /// Compact reference like `SB-7F3A91`.
    private static func generateReferenceCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let suffix = (0..<6).map { _ in alphabet.randomElement()! }
        return "SB-" + String(suffix)
    }
}
