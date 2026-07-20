//
//  MockData.swift
//  SlotBook
//
//  Badminton clubs, courts, and simulated availability.
//  Replace via ClubRepository when Supabase is wired.
//

import Foundation

enum MockData {
    // Stable IDs for navigation and future API mapping.
    nonisolated static let torontoClubId = UUID(uuidString: "b1111111-1111-1111-1111-111111111101")!
    nonisolated static let willowdaleClubId = UUID(uuidString: "b1111111-1111-1111-1111-111111111102")!
    nonisolated static let northYorkClubId = UUID(uuidString: "b1111111-1111-1111-1111-111111111103")!

    /// Three GTA clubs per product requirements.
    nonisolated static let clubs: [BadmintonClub] = [
        BadmintonClub(
            id: torontoClubId,
            name: "Toronto Badminton Club",
            description: "Downtown’s premier indoor badminton destination. Ten climate-controlled courts, coaching programs, and evening open play for all levels.",
            imageName: "figure.badminton",
            address: "100 Queens Quay W",
            city: "Toronto",
            totalCourts: 10,
            primaryColor: ItemColor(r: 37, g: 99, b: 235),
            tagline: "10 courts · Downtown",
            amenities: ["Parking", "Pro shop", "Showers", "Coaching"],
            pricePerHourCAD: 28,
            isIndoor: true,
            hasCoaching: true,
            openingHours: "6:00 AM – 11:00 PM"
        ),
        BadmintonClub(
            id: willowdaleClubId,
            name: "Willowdale Badminton Centre",
            description: "A calm North Toronto club with eight well-lit courts, flexible hourly booking, and a friendly community from beginners to advanced doubles.",
            imageName: "sportscourt.fill",
            address: "4800 Yonge St",
            city: "North York",
            totalCourts: 8,
            primaryColor: ItemColor(r: 22, g: 163, b: 74),
            tagline: "8 courts · Willowdale",
            amenities: ["Transit nearby", "Lockers", "Stringing"],
            pricePerHourCAD: 24,
            isIndoor: true,
            hasCoaching: false,
            openingHours: "7:00 AM – 10:00 PM"
        ),
        BadmintonClub(
            id: northYorkClubId,
            name: "North York Badminton Arena",
            description: "Twelve courts under one roof — ideal for leagues, private sessions, and weekend peak play. Easy access from the 401 corridor.",
            imageName: "building.2.fill",
            address: "5800 Finch Ave E",
            city: "North York",
            totalCourts: 12,
            primaryColor: ItemColor(r: 124, g: 58, b: 237),
            tagline: "12 courts · North York",
            amenities: ["Large parking", "Café", "League nights", "Rentals", "Coaching"],
            pricePerHourCAD: 26,
            isIndoor: true,
            hasCoaching: true,
            openingHours: "6:30 AM – 12:00 AM"
        ),
    ]

    /// Hidden court inventory. Stable UUIDs for deterministic availability.
    nonisolated static let courts: [Court] = {
        clubs.flatMap { club in
            (1...club.totalCourts).map { number in
                Court(
                    id: stableCourtId(clubId: club.id, courtNumber: number),
                    clubId: club.id,
                    courtNumber: number,
                    isActive: true
                )
            }
        }
    }()

    private nonisolated static func stableCourtId(clubId: UUID, courtNumber: Int) -> UUID {
        let clubTail = clubId.uuidString.replacingOccurrences(of: "-", with: "").suffix(12)
        let courtHex = String(format: "%04x", courtNumber)
        let idString = "c\(courtHex)0000-0000-4000-8000-\(clubTail)"
        return UUID(uuidString: idString) ?? UUID()
    }

    nonisolated static func club(id: UUID) -> BadmintonClub? {
        clubs.first { $0.id == id }
    }

    nonisolated static func courts(for clubId: UUID) -> [Court] {
        courts.filter { $0.clubId == clubId && $0.isActive }
    }

    // MARK: - Simulated bookings (hidden court inventory)

    /// Deterministic busy intervals so peak hours look realistic across reloads.
    nonisolated static func mockBusyIntervals(
        clubId: UUID,
        on day: Date,
        calendar: Calendar = .current
    ) -> [CourtBusyInterval] {
        let clubCourts = courts(for: clubId)
        guard !clubCourts.isEmpty else { return [] }

        let dayStart = calendar.startOfDay(for: day)
        var busy: [CourtBusyInterval] = []
        let daySalt = Int(dayStart.timeIntervalSinceReferenceDate) / 86_400

        for court in clubCourts {
            for hour in [10, 11, 12, 17, 18, 19, 20] {
                let seed = stableBusySeed(
                    clubId: clubId,
                    courtNumber: court.courtNumber,
                    daySalt: daySalt,
                    hour: hour
                )
                // ~1 in 3 peak hours booked on this court (60 min).
                guard seed % 3 == 0 else { continue }

                let minute = (seed % 2 == 0) ? 0 : 30
                guard
                    let start = calendar.date(
                        bySettingHour: hour,
                        minute: minute,
                        second: 0,
                        of: dayStart
                    ),
                    let end = calendar.date(byAdding: .minute, value: 60, to: start)
                else { continue }

                busy.append(CourtBusyInterval(courtId: court.id, start: start, end: end))
            }

            // Occasional 90-min mid-afternoon blocks on even courts.
            if court.courtNumber % 2 == 0 {
                let seed = stableBusySeed(
                    clubId: clubId,
                    courtNumber: court.courtNumber,
                    daySalt: daySalt,
                    hour: 14
                )
                if seed % 4 == 0,
                   let start = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: dayStart),
                   let end = calendar.date(byAdding: .minute, value: 90, to: start) {
                    busy.append(CourtBusyInterval(courtId: court.id, start: start, end: end))
                }
            }
        }

        return busy
    }

    /// Player-facing start options (courts never exposed).
    nonisolated static func findAvailableSlots(
        clubId: UUID,
        date: Date,
        durationMinutes: Int,
        additionalBusy: [CourtBusyInterval] = [],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [ClubStartOption] {
        let mockBusy = mockBusyIntervals(clubId: clubId, on: date, calendar: calendar)
        return CourtAvailabilityEngine.findAvailableSlots(
            clubId: clubId,
            date: date,
            durationMinutes: durationMinutes,
            courts: courts(for: clubId),
            busy: mockBusy + additionalBusy,
            now: now,
            calendar: calendar
        )
    }

    /// Stable non-crypto seed (Swift `Hasher` is process-randomized).
    private nonisolated static func stableBusySeed(
        clubId: UUID,
        courtNumber: Int,
        daySalt: Int,
        hour: Int
    ) -> Int {
        let u = clubId.uuid
        let clubMix = Int(u.12) &<< 24 | Int(u.13) &<< 16 | Int(u.14) &<< 8 | Int(u.15)
        var value = clubMix &+ courtNumber &* 131 &+ daySalt &* 17 &+ hour &* 53
        value = value &* 1_664_525 &+ 1_013_904_223
        return abs(value)
    }
}
