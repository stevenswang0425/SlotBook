//
//  RepositoryContainer.swift
//  SlotBook
//
//  Composition root for data dependencies.
//  Swap mock repos for Supabase implementations here only.
//

import Foundation
import Observation
import SwiftUI

/// Holds repository implementations for injection.
@Observable
@MainActor
final class RepositoryContainer {
    let items: any ItemRepository
    let bookings: any BookingRepository

    /// Production MVP defaults — mock implementations.
    init(
        items: any ItemRepository = MockItemRepository(),
        bookings: any BookingRepository = MockBookingRepository()
    ) {
        self.items = items
        self.bookings = bookings
    }

    /// Example factory for a future Supabase build configuration.
    ///
    /// ```swift
    /// // #if SUPABASE
    /// // return RepositoryContainer(
    /// //     items: SupabaseItemRepository(client: client),
    /// //     bookings: SupabaseBookingRepository(client: client)
    /// // )
    /// // #endif
    /// ```
    static func makeDefault() -> RepositoryContainer {
        RepositoryContainer()
    }
}

// MARK: - Environment

private struct RepositoryContainerKey: EnvironmentKey {
    @MainActor static var defaultValue: RepositoryContainer { .makeDefault() }
}

extension EnvironmentValues {
    var repositories: RepositoryContainer {
        get { self[RepositoryContainerKey.self] }
        set { self[RepositoryContainerKey.self] = newValue }
    }
}

extension View {
    func repositories(_ container: RepositoryContainer) -> some View {
        environment(\.repositories, container)
    }
}
