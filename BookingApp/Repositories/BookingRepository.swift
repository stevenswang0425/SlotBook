//
//  BookingRepository.swift
//  SlotBook
//
//  Data-access protocol for bookings (create / list / cancel).
//
//  ─────────────────────────────────────────────────────────────────────────
//  FUTURE SUPABASE INTEGRATION
//
//    final class SupabaseBookingRepository: BookingRepository {
//        let client: SupabaseClient
//
//        func createBooking(_ draft: BookingDraft) async throws -> Booking {
//            // try await client.from("bookings").insert(draft).select().single().execute().value
//        }
//
//        func cancelBooking(id: UUID) async throws {
//            // try await client.from("bookings").update(["status": "cancelled"]).eq("id", id).execute()
//        }
//
//        func fetchBookings() async throws -> [Booking] {
//            // try await client.from("bookings").select("*, item:items(*)").execute().value
//        }
//    }
//
//  Realtime: subscribe to `postgres_changes` on `slots` / `bookings` and
//  forward events into `BookingStore` (replacing RealtimeAvailabilitySimulator).
//  ─────────────────────────────────────────────────────────────────────────
//

import Foundation

/// Payload required to create a booking (maps cleanly to a REST/Supabase insert).
struct BookingDraft: Sendable {
    let item: Item
    let slot: TimeSlot
    let date: Date
    let guestName: String
    let phoneDigits: String
}

/// Abstraction over booking persistence.
protocol BookingRepository: Sendable {
    func fetchBookings() async throws -> [Booking]
    func createBooking(_ draft: BookingDraft) async throws -> Booking
    func cancelBooking(id: UUID) async throws -> Booking
}

/// In-memory mock that mirrors `BookingStore` for the MVP.
///
/// Note: The UI still uses `BookingStore` as the live cache. This repository
/// is the seam where Supabase (or any API) will plug in; the mock keeps the
/// architecture honest without duplicating state.
struct MockBookingRepository: BookingRepository {
    var simulatedDelay: Duration = .milliseconds(400)

    func fetchBookings() async throws -> [Booking] {
        try? await Task.sleep(for: simulatedDelay)
        // Backend swap-point: remote list query.
        return []
    }

    func createBooking(_ draft: BookingDraft) async throws -> Booking {
        try? await Task.sleep(for: simulatedDelay)
        // Backend swap-point: insert row, return server-authored booking.
        return Booking.make(
            item: draft.item,
            slot: draft.slot,
            date: draft.date,
            guestName: draft.guestName,
            phoneDigits: draft.phoneDigits
        )
    }

    func cancelBooking(id: UUID) async throws -> Booking {
        try? await Task.sleep(for: simulatedDelay)
        // Backend swap-point: PATCH status = cancelled.
        // Caller applies the result to BookingStore.
        throw BookingRepositoryError.notImplementedInMock(id: id)
    }
}

enum BookingRepositoryError: LocalizedError {
    case notImplementedInMock(id: UUID)
    case remote(String)

    var errorDescription: String? {
        switch self {
        case .notImplementedInMock:
            return "Mock cancel is handled by BookingStore in the MVP."
        case .remote(let message):
            return message
        }
    }
}
