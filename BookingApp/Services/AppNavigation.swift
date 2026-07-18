//
//  AppNavigation.swift
//  SlotBook
//
//  Lightweight app navigation state (selected tab, etc.).
//

import Foundation
import Observation
import SwiftUI

/// Root tab identifiers shared by MainTabView and deep links (e.g. post-booking).
enum AppTab: Hashable, Sendable {
    case home
    case bookings
    case profile
}

/// Coordinates cross-screen navigation without tight coupling.
@Observable
@MainActor
final class AppNavigation {
    var selectedTab: AppTab = .home

    func openBookings() {
        selectedTab = .bookings
    }

    func openHome() {
        selectedTab = .home
    }
}

// MARK: - Environment

private struct AppNavigationKey: EnvironmentKey {
    @MainActor static var defaultValue: AppNavigation { AppNavigation() }
}

extension EnvironmentValues {
    var appNavigation: AppNavigation {
        get { self[AppNavigationKey.self] }
        set { self[AppNavigationKey.self] = newValue }
    }
}

extension View {
    func appNavigation(_ navigation: AppNavigation) -> some View {
        environment(\.appNavigation, navigation)
    }
}
