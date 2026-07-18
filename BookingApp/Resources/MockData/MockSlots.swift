//
//  MockSlots.swift
//  SlotBook
//
//  Deterministic mock slot generation for Item Detail.
//  Swap for a live availability API in a later iteration.
//

import Foundation

enum MockSlots {
    /// Business-hour window (local calendar).
    nonisolated static let dayStartHour = 9
    nonisolated static let dayEndHour = 17
    /// Interval between slot starts, in minutes.
    nonisolated static let intervalMinutes = 30

    /// Builds half-hour slots for a calendar day with a stable booked pattern.
    ///
    /// Booking pattern is seeded by the item + day so it stays consistent across reloads,
    /// while still looking natural (roughly every 3rd–4th window booked).
    nonisolated static func slots(
        for day: Date,
        itemID: UUID,
        calendar: Calendar = .current
    ) -> [TimeSlot] {
        guard let dayStart = calendar.dateInterval(of: .day, for: day)?.start else {
            return []
        }

        var results: [TimeSlot] = []
        var hour = dayStartHour
        var minute = 0
        var index = 0

        while hour < dayEndHour || (hour == dayEndHour && minute == 0) {
            // Stop before creating a slot that would end after closing.
            if hour == dayEndHour { break }

            guard
                let start = calendar.date(
                    bySettingHour: hour,
                    minute: minute,
                    second: 0,
                    of: dayStart
                ),
                let end = calendar.date(byAdding: .minute, value: intervalMinutes, to: start)
            else {
                break
            }

            // Stable pseudo-random booking: mix item id + day + index.
            let seed = stableSeed(itemID: itemID, dayStart: dayStart, index: index)
            let isBooked = seed % 4 == 0 // ~25% booked

            results.append(
                TimeSlot(
                    id: stableSlotID(itemID: itemID, start: start),
                    start: start,
                    end: end,
                    availability: isBooked ? .booked : .available
                )
            )

            index += 1
            minute += intervalMinutes
            if minute >= 60 {
                minute = 0
                hour += 1
            }
        }

        return results
    }

    /// Next `count` calendar days starting from today (inclusive).
    nonisolated static func upcomingDays(
        count: Int = 14,
        from reference: Date = Date(),
        calendar: Calendar = .current
    ) -> [SelectableDay] {
        let start = calendar.startOfDay(for: reference)
        return (0..<count).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else {
                return nil
            }
            return SelectableDay(date: date)
        }
    }

    // MARK: - Stable IDs

    private nonisolated static func stableSeed(itemID: UUID, dayStart: Date, index: Int) -> Int {
        var hasher = Hasher()
        hasher.combine(itemID)
        hasher.combine(dayStart.timeIntervalSinceReferenceDate)
        hasher.combine(index)
        return abs(hasher.finalize())
    }

    private nonisolated static func stableSlotID(itemID: UUID, start: Date) -> UUID {
        // Derive a deterministic UUID-like identity from item + start time.
        var hasher = Hasher()
        hasher.combine(itemID)
        hasher.combine(start.timeIntervalSinceReferenceDate)
        let hash = UInt64(bitPattern: Int64(hasher.finalize()))
        // Build a UUID from the hash + item bytes for stable identity across sessions.
        let bytes = itemID.uuid
        return UUID(
            uuid: (
                bytes.0, bytes.1, bytes.2, bytes.3,
                UInt8((hash >> 56) & 0xFF), UInt8((hash >> 48) & 0xFF),
                UInt8((hash >> 40) & 0xFF), UInt8((hash >> 32) & 0xFF),
                UInt8((hash >> 24) & 0xFF), UInt8((hash >> 16) & 0xFF),
                UInt8((hash >> 8) & 0xFF), UInt8(hash & 0xFF),
                bytes.12, bytes.13, bytes.14, bytes.15
            )
        )
    }
}
