//
//  AppTheme.swift
//  SlotBook
//
//  Brandable color palettes for multi-store theming.
//
//  How to rebrand
//  ──────────────
//  1. Pick a preset in Settings → Appearance → Brand color, or
//  2. Call `themeManager.apply(.forest)` / `.violet` / `.ocean`, or
//  3. Add a new `ThemePreset` case with your RGB values below.
//
//  Neutrals (background, card, text) stay in Assets.xcassets so Light/Dark
//  mode keeps working without per-brand asset catalogs.
//

import SwiftUI

/// Identifiers for built-in store branding presets.
enum ThemePreset: String, CaseIterable, Identifiable, Codable, Sendable {
    case ocean
    case forest
    case violet

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ocean: return "Ocean Blue"
        case .forest: return "Forest Green"
        case .violet: return "Violet"
        }
    }

    var subtitle: String {
        switch self {
        case .ocean: return "Default SlotBook calm blue"
        case .forest: return "Wellness & nature brands"
        case .violet: return "Creative studios & salons"
        }
    }

    /// SF Symbol hint shown on the theme picker.
    var symbolName: String {
        switch self {
        case .ocean: return "drop.fill"
        case .forest: return "leaf.fill"
        case .violet: return "sparkles"
        }
    }

    /// Primary brand color (light-mode base; still readable on dark surfaces).
    var primary: Color {
        switch self {
        case .ocean: return Color(red: 37 / 255, green: 99 / 255, blue: 235 / 255)   // #2563EB
        case .forest: return Color(red: 22 / 255, green: 163 / 255, blue: 74 / 255)  // #16A34A
        case .violet: return Color(red: 124 / 255, green: 58 / 255, blue: 237 / 255) // #7C3AED
        }
    }

    /// Soft wash used for selected chips / muted fills.
    var primaryMuted: Color {
        switch self {
        case .ocean: return Color(red: 219 / 255, green: 234 / 255, blue: 254 / 255)  // #DBEAFE
        case .forest: return Color(red: 220 / 255, green: 252 / 255, blue: 231 / 255) // #DCFCE7
        case .violet: return Color(red: 237 / 255, green: 233 / 255, blue: 254 / 255) // #EDE9FE
        }
    }

    /// Slightly brighter primary for dark mode accents.
    var primaryDarkMode: Color {
        switch self {
        case .ocean: return Color(red: 96 / 255, green: 165 / 255, blue: 250 / 255)  // #60A5FA
        case .forest: return Color(red: 74 / 255, green: 222 / 255, blue: 128 / 255) // #4ADE80
        case .violet: return Color(red: 167 / 255, green: 139 / 255, blue: 250 / 255) // #A78BFA
        }
    }

    var primaryMutedDarkMode: Color {
        switch self {
        case .ocean: return Color(red: 30 / 255, green: 58 / 255, blue: 95 / 255)
        case .forest: return Color(red: 20 / 255, green: 60 / 255, blue: 40 / 255)
        case .violet: return Color(red: 46 / 255, green: 30 / 255, blue: 80 / 255)
        }
    }

    /// Resolved primary for the current color scheme.
    func primary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? primaryDarkMode : primary
    }

    func primaryMuted(for scheme: ColorScheme) -> Color {
        scheme == .dark ? primaryMutedDarkMode : primaryMuted
    }

    var brandTheme: BrandTheme {
        BrandTheme(
            appName: "SlotBook",
            logoSymbol: "calendar.badge.clock",
            primaryOverride: primary,
            cornerRadiusScale: 1.0,
            preset: self
        )
    }
}

/// Runtime theme snapshot used by views (preset + appearance preference).
struct AppTheme: Equatable, Sendable {
    var preset: ThemePreset
    /// `nil` = follow system Light/Dark.
    var colorSchemeOverride: ColorScheme?

    static let `default` = AppTheme(preset: .ocean, colorSchemeOverride: nil)
}

// MARK: - ColorScheme Codable helpers

extension ColorScheme {
    var storageValue: String {
        switch self {
        case .light: return "light"
        case .dark: return "dark"
        @unknown default: return "light"
        }
    }

    static func from(storage: String?) -> ColorScheme? {
        switch storage {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
