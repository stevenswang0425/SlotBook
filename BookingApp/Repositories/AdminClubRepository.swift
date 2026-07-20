//
//  AdminClubRepository.swift
//  SlotBook
//
//  Owner admin data access for clubs & courts (mock-first).
//
//  FUTURE SUPABASE:
//    - stores where owner_id = auth.uid()
//    - courts table (visible only via owner RLS)
//    - bookings select with court_number for admin role
//

import Foundation

protocol AdminClubRepository: Sendable {
    func fetchManagedClubs() async throws -> [AdminManagedClub]
    func fetchManagedCourts(clubId: UUID) async throws -> [AdminManagedCourt]
    func updateClub(_ club: AdminManagedClub) async throws -> AdminManagedClub
    func setCourtActive(courtId: UUID, isActive: Bool) async throws -> AdminManagedCourt
    func addCourt(clubId: UUID) async throws -> AdminManagedCourt
    func removeCourt(courtId: UUID) async throws
}

/// In-memory admin inventory seeded from public MockData.
/// Mutations stay local to the app session (MVP). Shared singleton so Store + Detail share state.
actor MockAdminClubRepository: AdminClubRepository {
    private var clubs: [AdminManagedClub]
    private var courts: [AdminManagedCourt]
    var simulatedDelay: Duration = .milliseconds(280)

    /// Shared instance so club edits / court toggles persist across admin screens.
    static let shared = MockAdminClubRepository()

    init() {
        self.clubs = MockData.clubs.map(AdminManagedClub.from)
        self.courts = MockData.courts.map(AdminManagedCourt.from)
    }

    func fetchManagedClubs() async throws -> [AdminManagedClub] {
        try? await Task.sleep(for: simulatedDelay)
        return clubs.sorted { $0.name < $1.name }
    }

    func fetchManagedCourts(clubId: UUID) async throws -> [AdminManagedCourt] {
        try? await Task.sleep(for: .milliseconds(150))
        return courts
            .filter { $0.clubId == clubId }
            .sorted { $0.courtNumber < $1.courtNumber }
    }

    func updateClub(_ club: AdminManagedClub) async throws -> AdminManagedClub {
        try? await Task.sleep(for: simulatedDelay)
        guard let index = clubs.firstIndex(where: { $0.id == club.id }) else {
            throw AdminClubRepositoryError.notFound
        }
        clubs[index] = club
        return club
    }

    func setCourtActive(courtId: UUID, isActive: Bool) async throws -> AdminManagedCourt {
        try? await Task.sleep(for: .milliseconds(180))
        guard let index = courts.firstIndex(where: { $0.id == courtId }) else {
            throw AdminClubRepositoryError.notFound
        }
        courts[index].isActive = isActive
        return courts[index]
    }

    func addCourt(clubId: UUID) async throws -> AdminManagedCourt {
        try? await Task.sleep(for: simulatedDelay)
        let existing = courts.filter { $0.clubId == clubId }
        let nextNumber = (existing.map(\.courtNumber).max() ?? 0) + 1
        let court = AdminManagedCourt(
            id: UUID(),
            clubId: clubId,
            courtNumber: nextNumber,
            isActive: true
        )
        courts.append(court)
        return court
    }

    func removeCourt(courtId: UUID) async throws {
        try? await Task.sleep(for: .milliseconds(200))
        courts.removeAll { $0.id == courtId }
    }
}

enum AdminClubRepositoryError: LocalizedError {
    case notFound
    case remote(String)

    var errorDescription: String? {
        switch self {
        case .notFound: return "Club or court not found."
        case .remote(let message): return message
        }
    }
}
