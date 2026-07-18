//
//  BrandTheme.swift
//  SlotBook
//
//  Per-store branding configuration consumed by chrome (logo, radii).
//  Color accents live on ThemePreset / ThemeManager for dynamic switching.
//

import SwiftUI

/// Describes visual brand identity for a storefront or tenant.
struct BrandTheme: Equatable, Sendable {
    /// Display name shown in the nav bar / about screens.
    var appName: String

    /// SF Symbol used next to the logo wordmark.
    var logoSymbol: String

    /// Optional primary override (prefer ThemeManager.preset in new code).
    var primaryOverride: Color?

    /// Corner radius multiplier for brand-specific softness (1.0 = default).
    var cornerRadiusScale: CGFloat

    /// Linked palette preset when driven by ThemeManager.
    var preset: ThemePreset

    /// Default SlotBook theme — Ocean blue.
    static let slotBook = BrandTheme(
        appName: "SlotBook",
        logoSymbol: "calendar.badge.clock",
        primaryOverride: ThemePreset.ocean.primary,
        cornerRadiusScale: 1.0,
        preset: .ocean
    )

    /// Active theme used by a few legacy call sites.
    @MainActor
    static var current: BrandTheme = .slotBook
}

// MARK: - Environment

private struct BrandThemeKey: EnvironmentKey {
    static let defaultValue: BrandTheme = .slotBook
}

extension EnvironmentValues {
    var brandTheme: BrandTheme {
        get { self[BrandThemeKey.self] }
        set { self[BrandThemeKey.self] = newValue }
    }
}

extension View {
    func brandTheme(_ theme: BrandTheme) -> some View {
        environment(\.brandTheme, theme)
    }
}
