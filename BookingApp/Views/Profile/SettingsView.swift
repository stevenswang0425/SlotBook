//
//  SettingsView.swift
//  SlotBook
//
//  Simple settings: brand theme, appearance, notifications placeholder.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        List {
            brandSection
            appearanceSection
            notificationsSection
            aboutSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(SBColor.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Brand

    private var brandSection: some View {
        Section {
            ForEach(ThemePreset.allCases) { preset in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                        themeManager.apply(preset)
                    }
                } label: {
                    HStack(spacing: Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(preset.primary(for: colorScheme))
                                .frame(width: 28, height: 28)
                            Image(systemName: preset.symbolName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.displayName)
                                .sbFontSubheadline()
                            Text(preset.subtitle)
                                .sbFontCaption()
                        }

                        Spacer()

                        if themeManager.preset == preset {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(preset.primary(for: colorScheme))
                                .accessibilityLabel("Selected")
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(SBColor.card)
            }
        } header: {
            Text("Brand color")
        } footer: {
            Text("Swap palettes to preview multi-store branding. In production this can come from a store profile.")
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section {
            appearanceRow(title: "System", scheme: nil, symbol: "circle.lefthalf.filled")
            appearanceRow(title: "Light", scheme: .light, symbol: "sun.max.fill")
            appearanceRow(title: "Dark", scheme: .dark, symbol: "moon.fill")
        } header: {
            Text("Appearance")
        }
    }

    private func appearanceRow(title: String, scheme: ColorScheme?, symbol: String) -> some View {
        let selected = themeManager.colorSchemeOverride == scheme
            || (scheme == nil && themeManager.colorSchemeOverride == nil)

        return Button {
            themeManager.setAppearance(scheme)
        } label: {
            HStack {
                Label(title, systemImage: symbol)
                    .foregroundStyle(SBColor.textPrimary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(themeManager.preset.primary(for: colorScheme))
                        .fontWeight(.semibold)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(SBColor.card)
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: notificationsBinding) {
                Label("Booking reminders", systemImage: "bell.badge")
            }
            .tint(themeManager.preset.primary(for: colorScheme))
            .listRowBackground(SBColor.card)
        } header: {
            Text("Notifications")
        } footer: {
            Text("Placeholder for future push / local notifications. No system permission is requested yet.")
        }
    }

    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { themeManager.notificationsEnabled },
            set: { themeManager.notificationsEnabled = $0 }
        )
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            LabeledContent("App", value: "SlotBook")
                .listRowBackground(SBColor.card)
            LabeledContent("Version", value: appVersion)
                .listRowBackground(SBColor.card)
            LabeledContent("Build", value: "MVP")
                .listRowBackground(SBColor.card)
        } header: {
            Text("About")
        } footer: {
            Text("SlotBook MVP — calm real-time booking. Backend-ready via repository layer.")
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Previews

#Preview("Settings — Light") {
    NavigationStack {
        SettingsView()
    }
    .themeManager(ThemeManager())
}

#Preview("Settings — Dark Forest") {
    let tm = ThemeManager()
    tm.apply(.forest)
    tm.setAppearance(.dark)
    return NavigationStack {
        SettingsView()
    }
    .themeManager(tm)
    .preferredColorScheme(.dark)
}
