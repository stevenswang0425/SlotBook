//
//  MainTabView.swift
//  SlotBook
//
//  Root tab navigation: Home, My Bookings, Profile.
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.appNavigation) private var appNavigation
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView(selection: tabSelection) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "square.grid.2x2.fill")
                }
                .tag(AppTab.home)

            MyBookingsView()
                .tabItem {
                    Label("My Bookings", systemImage: "calendar")
                }
                .tag(AppTab.bookings)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(AppTab.profile)
        }
        .tint(themeManager.preset.primary(for: colorScheme))
    }

    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { appNavigation.selectedTab },
            set: { appNavigation.selectedTab = $0 }
        )
    }
}

#Preview("Tabs — Light") {
    MainTabView()
        .themeManager(ThemeManager())
        .bookingStore(BookingStore())
        .appNavigation(AppNavigation())
        .repositories(.makeDefault())
}

#Preview("Tabs — Forest Dark") {
    let tm = ThemeManager()
    tm.apply(.forest)
    return MainTabView()
        .themeManager(tm)
        .bookingStore(BookingStore())
        .appNavigation(AppNavigation())
        .preferredColorScheme(.dark)
}
