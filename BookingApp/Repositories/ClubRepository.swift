//
//  ClubRepository.swift
//  SlotBook
//
//  Repository for badminton club discovery, availability, and court booking.
//
//  FUTURE SUPABASE:
//    final class SupabaseClubRepository: ClubRepository {
//        func createCourtBooking(_ request: CourtBookingCreateRequest) async throws -> CourtBooking {
//          // RPC: assign free court + insert booking in one transaction.
//          // Never return court_number to the client for player-facing APIs.
//        }
//    }
//

import Foundation

protocol ClubRepository: Sendable {
    func fetchClubs() async throws -> [BadmintonClub]
    func fetchClub(id: UUID) async throws -> BadmintonClub?
    func fetchCourts(clubId: UUID) async throws -> [Court]

    /// Player-facing availability. Courts stay hidden; only start times return.
    func findAvailableSlots(
        clubId: UUID,
        date: Date,
        durationMinutes: Int,
        additionalBusy: [CourtBusyInterval]
    ) async throws -> [ClubStartOption]

    /// Reserves a court internally and returns a confirmed booking (no court # in UI).
    func createCourtBooking(_ request: CourtBookingCreateRequest) async throws -> CourtBooking
}

struct MockClubRepository: ClubRepository {
    var simulatedDelay: Duration = .milliseconds(450)
    var slotsDelay: Duration = .milliseconds(280)
    var bookingDelay: Duration = .milliseconds(1_050)

    func fetchClubs() async throws -> [BadmintonClub] {
        try? await Task.sleep(for: simulatedDelay)
        return MockData.clubs
    }

    func fetchClub(id: UUID) async throws -> BadmintonClub? {
        try? await Task.sleep(for: .milliseconds(200))
        return MockData.club(id: id)
    }

    func fetchCourts(clubId: UUID) async throws -> [Court] {
        try? await Task.sleep(for: .milliseconds(200))
        return MockData.courts(for: clubId)
    }

    func findAvailableSlots(
        clubId: UUID,
        date: Date,
        durationMinutes: Int,
        additionalBusy: [CourtBusyInterval]
    ) async throws -> [ClubStartOption] {
        try? await Task.sleep(for: slotsDelay)
        return MockData.findAvailableSlots(
            clubId: clubId,
            date: date,
            durationMinutes: durationMinutes,
            additionalBusy: additionalBusy
        )
    }

    func createCourtBooking(_ request: CourtBookingCreateRequest) async throws -> CourtBooking {
        try? await Task.sleep(for: bookingDelay)

        let trimmedName = request.guestName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.count >= 2, PhoneNumberFormatter.isValid(digits: request.phoneDigits) else {
            throw CourtBookingError.invalidGuest
        }

        // Re-run auto-assignment at confirm time (handles races since the grid loaded).
        let courts = MockData.courts(for: request.clubId)
            .filter(\.isActive)
            .sorted { $0.courtNumber < $1.courtNumber }

        let mockBusy = MockData.mockBusyIntervals(clubId: request.clubId, on: request.start)
        let allBusy = mockBusy + request.additionalBusy

        guard let freeCourt = CourtAvailabilityEngine.firstFreeCourt(
            courts: courts,
            start: request.start,
            end: request.end,
            busy: allBusy
        ) else {
            throw CourtBookingError.slotUnavailable
        }

        // System-assigned court — callers must not surface courtNumber in player UI.
        return CourtBooking.make(
            clubId: request.clubId,
            clubName: request.clubName,
            courtId: freeCourt.id,
            courtNumber: freeCourt.courtNumber,
            slotId: request.slotId,
            start: request.start,
            end: request.end,
            durationMinutes: request.durationMinutes,
            guestName: trimmedName,
            phoneDigits: request.phoneDigits,
            email: request.email
        )
    }
}
