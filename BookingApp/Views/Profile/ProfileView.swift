//
//  ProfileView.swift
//  SlotBook
//
//  Profile tab with guest header and navigation into Settings.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.brandTheme) private var brandTheme
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appNavigation) private var appNavigation

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
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(themeManager.preset.primaryMuted(for: colorScheme))
                    .frame(width: 96, height: 96)

                Image(systemName: "person.fill")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(themeManager.preset.primary(for: colorScheme))
            }
            .padding(.top, Spacing.lg)
            .accessibilityHidden(true)

            VStack(spacing: Spacing.xxs) {
                Text("Guest")
                    .sbFontHeadline()
                Text("Sign in coming soon")
                    .sbFontCaption()
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Guest profile. Sign in coming soon.")
    }

    // MARK: - Links

    private var quickLinks: some View {
        VStack(spacing: Spacing.sm) {
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
                                    .stroke(selected ? preset.primary(for: colorScheme).opacity(0.5) : SBColor.border, lineWidth: 1)
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
}

// MARK: - Previews

#Preview("Profile — Light") {
    ProfileView()
        .themeManager(ThemeManager())
        .appNavigation(AppNavigation())
}

#Preview("Profile — Violet Dark") {
    let tm = ThemeManager()
    tm.apply(.violet)
    return ProfileView()
        .themeManager(tm)
        .appNavigation(AppNavigation())
        .preferredColorScheme(.dark)
}
