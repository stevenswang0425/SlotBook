//
//  ThemeManager.swift
//  SlotBook
//
//  Observable theme controller — switch store branding at runtime.
//  Persists choices to UserDefaults for a production-feel MVP.
//

import Observation
import SwiftUI

/// Central theme authority for SlotBook.
///
/// Inject at the app root:
/// ```swift
/// @State private var themeManager = ThemeManager()
/// MainTabView()
///   .environment(themeManager)
///   .preferredColorScheme(themeManager.colorSchemeOverride)
/// ```
@Observable
@MainActor
final class ThemeManager {

    // MARK: - Keys

    private enum Keys {
        static let preset = "slotbook.theme.preset"
        static let appearance = "slotbook.theme.appearance"
        static let notifications = "slotbook.settings.notifications"
    }

    // MARK: - State

    /// Active brand palette (Ocean / Forest / Violet).
    var preset: ThemePreset {
        didSet {
            UserDefaults.standard.set(preset.rawValue, forKey: Keys.preset)
            BrandTheme.current = preset.brandTheme
        }
    }

    /// Optional Light/Dark override (`nil` = system).
    var colorSchemeOverride: ColorScheme? {
        didSet {
            UserDefaults.standard.set(colorSchemeOverride?.storageValue, forKey: Keys.appearance)
        }
    }

    /// Placeholder notifications preference (Settings).
    var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notifications)
        }
    }

    /// Convenience snapshot.
    var appTheme: AppTheme {
        AppTheme(preset: preset, colorSchemeOverride: colorSchemeOverride)
    }

    // MARK: - Init

    init() {
        let raw = UserDefaults.standard.string(forKey: Keys.preset) ?? ThemePreset.ocean.rawValue
        self.preset = ThemePreset(rawValue: raw) ?? .ocean

        let appearance = UserDefaults.standard.string(forKey: Keys.appearance)
        self.colorSchemeOverride = ColorScheme.from(storage: appearance)

        self.notificationsEnabled = UserDefaults.standard.bool(forKey: Keys.notifications)

        BrandTheme.current = preset.brandTheme
    }

    // MARK: - API

    func apply(_ preset: ThemePreset) {
        self.preset = preset
        HapticFeedback.selection()
    }

    func setAppearance(_ scheme: ColorScheme?) {
        colorSchemeOverride = scheme
        HapticFeedback.selection()
    }

    /// Primary color resolved for a given scheme (for previews / non-view code).
    func primary(for scheme: ColorScheme) -> Color {
        preset.primary(for: scheme)
    }
}

// MARK: - Environment

private struct ThemeManagerKey: EnvironmentKey {
    @MainActor static var defaultValue: ThemeManager { ThemeManager() }
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

extension View {
    func themeManager(_ manager: ThemeManager) -> some View {
        environment(\.themeManager, manager)
            .environment(\.brandTheme, manager.preset.brandTheme)
    }
}
