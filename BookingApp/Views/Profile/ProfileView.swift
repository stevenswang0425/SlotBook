//
//  ProfileView.swift
//  SlotBook
//
//  Profile tab: guest/signed-in header, sign-in sheet, and a *hidden*
//  store-owner onboarding gesture (5 quick taps on the avatar).
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.brandTheme) private var brandTheme
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appNavigation) private var appNavigation
    @Environment(\.userSession) private var userSession

    @State private var showSignInSheet = false
    @State private var showBecomeOwnerSheet = false

    /// Secret gesture: 5 taps within a short window.
    @State private var avatarTapCount = 0
    @State private var avatarTapResetTask: Task<Void, Never>?

    private let secretTapThreshold = 5
    private let secretTapWindowNanoseconds: UInt64 = 1_800_000_000 // 1.8s

    var body: some View {
        NavigationStack {
            ZStack {
                SBColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        header
                        quickLinks
                        brandPreview
                    }
                    .padding(.bottom, Spacing.xxxl)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showSignInSheet) {
                SignInSheet()
            }
            .sheet(isPresented: $showBecomeOwnerSheet) {
                BecomeOwnerSheet()
            }
            .onDisappear {
                avatarTapResetTask?.cancel()
                avatarTapCount = 0
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Spacing.md) {
            avatar
                // No accessibility trait / label that reveals the secret path.
                .onTapGesture { handleSecretAvatarTap() }

            VStack(spacing: Spacing.xxs) {
                Text(userSession.displayName)
                    .sbFontHeadline()
                    .animation(.easeInOut(duration: 0.2), value: userSession.displayName)

                if userSession.isOwner {
                    adminModeBadge
                    if let phone = userSession.currentUser?.phone {
                        Text(phone)
                            .sbFontCaption()
                    }
                } else if userSession.isSignedIn {
                    signedInCaption
                } else {
                    Text("Book faster when you sign in")
                        .sbFontCaption()
                }
            }

            if userSession.isOwner {
                PrimaryButton(title: "Open My Store") {
                    appNavigation.openAdmin()
                    HapticFeedback.selection()
                }
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.xs)

                SecondaryButton(title: "Sign Out") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        userSession.signOut()
                    }
                }
                .padding(.horizontal, Spacing.xxl)
            } else if userSession.isSignedIn {
                SecondaryButton(title: "Sign Out") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        userSession.signOut()
                    }
                }
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.xs)
            } else {
                PrimaryButton(title: "Sign In / Create Account") {
                    showSignInSheet = true
                    HapticFeedback.lightImpact()
                }
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.sm)
        .accessibilityElement(children: .contain)
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(themeManager.preset.primaryMuted(for: colorScheme))
                .frame(width: 96, height: 96)

            if userSession.isSignedIn {
                Text(initials(from: userSession.displayName))
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager.preset.primary(for: colorScheme))
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(themeManager.preset.primary(for: colorScheme))
            }
        }
        // Keep VoiceOver from advertising any special action.
        .accessibilityHidden(true)
        .contentShape(Circle())
    }

    @ViewBuilder
    private var signedInCaption: some View {
        if let email = userSession.currentUser?.email {
            Text(email)
                .sbFontCaption()
        } else if let phone = userSession.currentUser?.phone {
            Text(phone)
                .sbFontCaption()
        } else {
            Text("Signed in")
                .sbFontCaption()
        }
    }

    // MARK: - Secret gesture

    /// Increments a private tap counter; after 5 taps within ~1.8s, presents owner signup.
    private func handleSecretAvatarTap() {
        avatarTapCount += 1

        // Subtle ticks so the owner knows taps registered — still no UI chrome.
        if avatarTapCount < secretTapThreshold {
            HapticFeedback.lightImpact()
        }

        avatarTapResetTask?.cancel()
        avatarTapResetTask = Task {
            try? await Task.sleep(nanoseconds: secretTapWindowNanoseconds)
            guard !Task.isCancelled else { return }
            avatarTapCount = 0
        }

        if avatarTapCount >= secretTapThreshold {
            avatarTapResetTask?.cancel()
            avatarTapCount = 0
            HapticFeedback.success()
            showBecomeOwnerSheet = true
        }
    }

    // MARK: - Links

    private var adminModeBadge: some View {
        Text("Admin Mode")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(themeManager.preset.primary(for: colorScheme))
            )
            .accessibilityLabel("Admin Mode")
    }

    private var quickLinks: some View {
        VStack(spacing: Spacing.sm) {
            if userSession.isOwner {
                Button {
                    appNavigation.openAdmin()
                } label: {
                    settingsRow(
                        icon: "building.2.fill",
                        title: "My Store",
                        subtitle: "Services calendar & bookings"
                    )
                }
                .buttonStyle(SBPressableButtonStyle())
            }

            NavigationLink {
                SettingsView()
            } label: {
                settingsRow(
                    icon: "gearshape",
                    title: "Settings",
                    subtitle: "Theme, appearance, notifications"
                )
            }
            .buttonStyle(SBPressableButtonStyle())

            Button {
                appNavigation.openBookings()
            } label: {
                settingsRow(
                    icon: "calendar",
                    title: "My Bookings",
                    subtitle: "Upcoming and past reservations"
                )
            }
            .buttonStyle(SBPressableButtonStyle())
        }
        .padding(.horizontal, Spacing.xl)
    }

    private func settingsRow(icon: String, title: String, subtitle: String) -> some View {
        CardView(showsShadow: true, showsBorder: false) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                        .fill(themeManager.preset.primaryMuted(for: colorScheme))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(themeManager.preset.primary(for: colorScheme))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .sbFontSubheadline()
                    Text(subtitle)
                        .sbFontCaption()
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SBColor.textTertiary)
            }
        }
    }

    // MARK: - Brand strip

    private var brandPreview: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Active brand")
                .sbFontCaption()
                .padding(.horizontal, Spacing.xl)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(ThemePreset.allCases) { preset in
                        let selected = themeManager.preset == preset
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                                themeManager.apply(preset)
                            }
                        } label: {
                            VStack(spacing: Spacing.xs) {
                                Circle()
                                    .fill(preset.primary(for: colorScheme))
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if selected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                Text(preset.displayName)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(selected ? SBColor.textPrimary : SBColor.textSecondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 88)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                    .fill(SBColor.card)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                    .stroke(
                                        selected
                                            ? preset.primary(for: colorScheme).opacity(0.5)
                                            : SBColor.border,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(preset.displayName) theme")
                        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
                    }
                }
                .padding(.horizontal, Spacing.xl)
            }

            Text("\(brandTheme.appName) · \(themeManager.preset.displayName)")
                .sbFontCaption()
                .padding(.horizontal, Spacing.xl)
        }
        .padding(.top, Spacing.sm)
    }

    // MARK: - Helpers

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first.map(String.init) }
        return letters.joined().uppercased()
    }
}

// MARK: - Previews

#Preview("Profile — Guest") {
    ProfileView()
        .themeManager(ThemeManager())
        .appNavigation(AppNavigation())
        .userSession(UserSession())
}

#Preview("Profile — Owner") {
    let session = UserSession()
    session.becomeStoreOwner(
        StoreOwnerSignup(
            storeName: "Harbor Collective",
            phone: "(555) 010-2000",
            email: "hello@harbor.test",
            serviceDescription: "Cafe & wellness"
        )
    )
    return ProfileView()
        .themeManager(ThemeManager())
        .appNavigation(AppNavigation())
        .userSession(session)
}

#Preview("Profile — Dark") {
    ProfileView()
        .themeManager(ThemeManager())
        .appNavigation(AppNavigation())
        .userSession(UserSession())
        .preferredColorScheme(.dark)
}
