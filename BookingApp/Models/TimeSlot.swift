//
//  TimeSlot.swift
//  SlotBook
//
//  Bookable half-hour windows for an item on a given day.
//

import Foundation

/// Availability of a time window (selection lives in the view model).
nonisolated enum TimeSlotAvailability: String, Sendable, Hashable {
    case available
    case booked
}

/// A single bookable interval (typically 30 minutes).
nonisolated struct TimeSlot: Identifiable, Hashable, Sendable {
    let id: UUID
    let start: Date
    let end: Date
    var availability: TimeSlotAvailability

    var isBooked: Bool { availability == .booked }
    var isAvailable: Bool { availability == .available }

    /// Duration in minutes.
    var durationMinutes: Int {
        Int(end.timeIntervalSince(start) / 60)
    }
}

// MARK: - Formatting helpers (locale-aware)

extension TimeSlot {
    /// Compact range label, e.g. "9:00 – 9:30 AM".
    nonisolated func rangeLabel(
        locale: Locale = .current,
        calendar: Calendar = .current
    ) -> String {
        let startText = Self.timeFormatter(locale: locale).string(from: start)
        let endText = Self.timeFormatter(locale: locale).string(from: end)
        return "\(startText) – \(endText)"
    }

    /// Start-only label for dense grids, e.g. "9:00 AM".
    nonisolated func startLabel(locale: Locale = .current) -> String {
        Self.timeFormatter(locale: locale).string(from: start)
    }

    /// End-only label, e.g. "9:30 AM".
    nonisolated func endLabel(locale: Locale = .current) -> String {
        Self.timeFormatter(locale: locale).string(from: end)
    }

    nonisolated private static func timeFormatter(locale: Locale) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }
}
