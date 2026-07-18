//
//  ItemRepository.swift
//  SlotBook
//
//  Data-access protocol for the catalog of bookable items.
//
//  ─────────────────────────────────────────────────────────────────────────
//  FUTURE SUPABASE INTEGRATION
//  Replace `MockItemRepository` with something like:
//
//    final class SupabaseItemRepository: ItemRepository {
//        let client: SupabaseClient
//        func fetchItems() async throws -> [Item] {
//            // let rows: [ItemDTO] = try await client.from("items").select().execute().value
//            // return rows.map(Item.init(dto:))
//        }
//    }
//
//  Wire it in `RepositoryContainer` — views/view models stay unchanged.
//  ─────────────────────────────────────────────────────────────────────────
//

import Foundation

/// Abstraction over the experience catalog.
protocol ItemRepository: Sendable {
    /// Loads all bookable items for the current storefront.
    func fetchItems() async throws -> [Item]
}

/// In-memory mock used by the MVP.
struct MockItemRepository: ItemRepository {
    /// Artificial latency so skeleton / refresh UX is testable.
    var simulatedDelay: Duration = .milliseconds(500)

    func fetchItems() async throws -> [Item] {
        // Simulate network round-trip.
        try? await Task.sleep(for: simulatedDelay)
        // Backend swap-point: return remote payload instead of MockItems.catalog.
        return MockItems.catalog
    }
}
