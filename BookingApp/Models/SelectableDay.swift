//
//  SelectableDay.swift
//  SlotBook
//
//  A day chip in the horizontal date selector.
//

import Foundation

/// One day option in the detail date picker strip.
nonisolated struct SelectableDay: Identifiable, Hashable, Sendable {
    /// Start-of-day in the given calendar.
    let date: Date

    var id: Date { date }

    /// Weekday short name, e.g. "Mon".
    func weekdayLabel(locale: Locale = .current, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter.string(from: date)
    }

    /// Day-of-month number, e.g. "17".
    func dayNumberLabel(calendar: Calendar = .current) -> String {
        String(calendar.component(.day, from: date))
    }

    /// Month short name when useful, e.g. "Jul".
    func monthLabel(locale: Locale = .current, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        return formatter.string(from: date)
    }

    /// Full accessible title, e.g. "Monday, July 17".
    func accessibilityLabel(locale: Locale = .current, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
