//
//  MainTabView.swift
//  SlotBook
//
//  Root tabs: Home, (My Store when owner), My Bookings, Profile.
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.appNavigation) private var appNavigation
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.userSession) private var userSession

    var body: some View {
        TabView(selection: tabSelection) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "square.grid.2x2.fill")
                }
                .tag(AppTab.home)

            if userSession.isOwner {
                AdminStoreView()
                    .tabItem {
                        Label("My Store", systemImage: "building.2.fill")
                    }
                    .tag(AppTab.admin)
            }

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
        // If the user signs out while on Admin, bounce to Home.
        .onChange(of: userSession.isOwner) { _, isOwner in
            if !isOwner, appNavigation.selectedTab == .admin {
                appNavigation.openHome()
            }
        }
    }

    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { appNavigation.selectedTab },
            set: { appNavigation.selectedTab = $0 }
        )
    }
}

#Preview("Tabs — Owner") {
    let session = UserSession()
    session.becomeStoreOwner(
        StoreOwnerSignup(
            storeName: "Harbor Collective",
            phone: "(555) 010-2000",
            email: nil,
            serviceDescription: nil
        )
    )
    return MainTabView()
        .themeManager(ThemeManager())
        .bookingStore(BookingStore())
        .appNavigation(AppNavigation())
        .userSession(session)
        .repositories(.makeDefault())
}

#Preview("Tabs — Guest") {
    MainTabView()
        .themeManager(ThemeManager())
        .bookingStore(BookingStore())
        .appNavigation(AppNavigation())
        .userSession(UserSession())
        .repositories(.makeDefault())
}
