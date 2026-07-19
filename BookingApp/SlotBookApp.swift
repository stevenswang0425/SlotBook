//
//  SlotBookApp.swift
//  SlotBook
//
//  App entry — stores, theme, repositories, live availability simulator.
//

import SwiftUI

@main
struct SlotBookApp: App {
    @State private var bookingStore = BookingStore()
    @State private var appNavigation = AppNavigation()
    @State private var themeManager = ThemeManager()
    @State private var userSession = UserSession()
    @State private var repositories = RepositoryContainer.makeDefault()
    @State private var realtimeSimulator: RealtimeAvailabilitySimulator?
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .themeManager(themeManager)
                    .bookingStore(bookingStore)
                    .appNavigation(appNavigation)
                    .userSession(userSession)
                    .repositories(repositories)
                    // Rebuild chrome when brand palette changes so tint / accents update.
                    .id(themeManager.preset)
                    .preferredColorScheme(themeManager.colorSchemeOverride)
                    .tint(themeManager.preset.primary)

                if showSplash {
                    SplashOverlay()
                        .themeManager(themeManager)
                        .preferredColorScheme(themeManager.colorSchemeOverride)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                ThemeManager.sharedProxy = themeManager

                // Live multi-user simulation (replace with Supabase realtime later).
                if realtimeSimulator == nil {
                    let simulator = RealtimeAvailabilitySimulator(store: bookingStore)
                    realtimeSimulator = simulator
                    simulator.start()
                }

                // Calm branded intro, then fade into the app.
                try? await Task.sleep(for: .milliseconds(900))
                withAnimation(.easeOut(duration: 0.35)) {
                    showSplash = false
                }
            }
        }
    }
}
