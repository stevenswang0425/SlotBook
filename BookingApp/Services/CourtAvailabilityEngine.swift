//
//  CourtAvailabilityEngine.swift
//  SlotBook
//
//  Pure availability math for badminton courts.
//
//  Rules:
//  • Courts stay hidden — callers only get ClubStartOption (no court numbers).
//  • A start time is Available if ≥1 active court is free for the full duration.
//  • System auto-assigns the lowest court number among free courts.
//  • Fully booked start times still appear (gray) so players can scan the day.
//

import Foundation

enum CourtAvailabilityEngine {
    /// Operating window used when building candidate starts (local calendar).
    nonisolated static let openHour = 9
    nonisolated static let closeHour = 22
    /// Grid of candidate start times.
    nonisolated static let startIntervalMinutes = 30

    /// Builds player-facing start options for a club/day/duration.
    ///
    /// - Parameters:
    ///   - clubId: Club being booked.
    ///   - date: Any moment on the selected day.
    ///   - durationMinutes: 45 / 60 / 90.
    ///   - courts: Active inventory (hidden from UI).
    ///   - busy: All known reservations for this club (mock + live store).
    ///   - now: Used to mark past starts as unavailable.
    nonisolated static func findAvailableSlots(
        clubId: UUID,
        date: Date,
        durationMinutes: Int,
        courts: [Court],
        busy: [CourtBusyInterval],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [ClubStartOption] {
        let activeCourts = courts
            .filter { $0.clubId == clubId && $0.isActive }
            .sorted { $0.courtNumber < $1.courtNumber }

        guard !activeCourts.isEmpty,
              durationMinutes > 0,
              let dayStart = calendar.dateInterval(of: .day, for: date)?.start
        else {
            return []
        }

        let candidates = candidateStarts(
            dayStart: dayStart,
            durationMinutes: durationMinutes,
            calendar: calendar
        )

        return candidates.map { start in
            guard let end = calendar.date(byAdding: .minute, value: durationMinutes, to: start) else {
                return makeOption(
                    clubId: clubId,
                    start: start,
                    end: start,
                    durationMinutes: durationMinutes,
                    isAvailable: false,
                    assignedCourtId: nil
                )
            }

            // Past starts are not bookable.
            if start < now {
                return makeOption(
                    clubId: clubId,
                    start: start,
                    end: end,
                    durationMinutes: durationMinutes,
                    isAvailable: false,
                    assignedCourtId: nil
                )
            }

            let freeCourt = firstFreeCourt(
                courts: activeCourts,
                start: start,
                end: end,
                busy: busy
            )

            return makeOption(
                clubId: clubId,
                start: start,
                end: end,
                durationMinutes: durationMinutes,
                isAvailable: freeCourt != nil,
                assignedCourtId: freeCourt?.id
            )
        }
    }

    // MARK: - Internals

    /// Start times every `startIntervalMinutes` from open until a full duration fits before close.
    nonisolated static func candidateStarts(
        dayStart: Date,
        durationMinutes: Int,
        calendar: Calendar
    ) -> [Date] {
        guard
            let open = calendar.date(bySettingHour: openHour, minute: 0, second: 0, of: dayStart),
            let close = calendar.date(bySettingHour: closeHour, minute: 0, second: 0, of: dayStart)
        else {
            return []
        }

        var starts: [Date] = []
        var cursor = open
        while true {
            guard let end = calendar.date(byAdding: .minute, value: durationMinutes, to: cursor) else {
                break
            }
            if end > close { break }
            starts.append(cursor)
            guard let next = calendar.date(byAdding: .minute, value: startIntervalMinutes, to: cursor) else {
                break
            }
            cursor = next
        }
        return starts
    }

    /// Lowest court number free for [start, end).
    nonisolated static func firstFreeCourt(
        courts: [Court],
        start: Date,
        end: Date,
        busy: [CourtBusyInterval]
    ) -> Court? {
        for court in courts {
            let conflicts = busy.contains {
                $0.courtId == court.id && $0.overlaps(start, end)
            }
            if !conflicts {
                return court
            }
        }
        return nil
    }

    nonisolated private static func makeOption(
        clubId: UUID,
        start: Date,
        end: Date,
        durationMinutes: Int,
        isAvailable: Bool,
        assignedCourtId: UUID?
    ) -> ClubStartOption {
        ClubStartOption(
            id: stableOptionID(clubId: clubId, start: start, durationMinutes: durationMinutes),
            clubId: clubId,
            start: start,
            end: end,
            durationMinutes: durationMinutes,
            isAvailable: isAvailable,
            assignedCourtId: assignedCourtId
        )
    }

    /// Deterministic ID so selection survives reloads for the same block.
    /// Encodes club bytes + local Y/M/D/H/M + duration (stable across launches).
    nonisolated static func stableOptionID(
        clubId: UUID,
        start: Date,
        durationMinutes: Int,
        calendar: Calendar = .current
    ) -> UUID {
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: start)
        let y = c.year ?? 2000
        let m = c.month ?? 1
        let d = c.day ?? 1
        let h = c.hour ?? 0
        let min = c.minute ?? 0
        let u = clubId.uuid
        let dateCode = UInt32(((y - 2000) & 0xFF) << 16 | (m & 0xFF) << 8 | (d & 0xFF))
        let clock = UInt16((h & 0xFF) << 8 | (min & 0xFF))
        let dur = UInt16(durationMinutes & 0xFFFF)
        return UUID(
            uuid: (
                u.0, u.1, u.2, u.3,
                UInt8(truncatingIfNeeded: dateCode >> 24),
                UInt8(truncatingIfNeeded: dateCode >> 16),
                UInt8(truncatingIfNeeded: dateCode >> 8),
                UInt8(truncatingIfNeeded: dateCode),
                UInt8(truncatingIfNeeded: clock >> 8),
                UInt8(truncatingIfNeeded: clock),
                UInt8(truncatingIfNeeded: dur >> 8),
                UInt8(truncatingIfNeeded: dur),
                u.12, u.13, u.14, u.15
            )
        )
    }
}
