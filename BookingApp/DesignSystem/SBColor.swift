//
//  SBColor.swift
//  SlotBook
//
//  Semantic colors. Neutrals come from Assets (Light/Dark adaptive).
//  Brand accents resolve from ThemeManager so store branding can change live.
//

import SwiftUI

/// Namespace for SlotBook semantic colors.
enum SBColor {
    // MARK: - Brand (dynamic via ThemeManager)

    /// Primary brand accent — follows the active `ThemePreset`.
    @MainActor
    static var primary: Color {
        ThemeManager.sharedProxy?.preset.primary
            ?? BrandTheme.current.primaryOverride
            ?? Color("BrandPrimary")
    }

    /// Soft tint of the primary color.
    @MainActor
    static var primaryMuted: Color {
        ThemeManager.sharedProxy?.preset.primaryMuted
            ?? Color("BrandPrimaryMuted")
    }

    /// Primary resolved for an explicit color scheme (useful in dark mode).
    @MainActor
    static func primary(for scheme: ColorScheme) -> Color {
        let preset = ThemeManager.sharedProxy?.preset ?? .ocean
        return preset.primary(for: scheme)
    }

    @MainActor
    static func primaryMuted(for scheme: ColorScheme) -> Color {
        let preset = ThemeManager.sharedProxy?.preset ?? .ocean
        return preset.primaryMuted(for: scheme)
    }

    // MARK: - Surfaces

    static let background = Color("Background")
    static let backgroundSecondary = Color("BackgroundSecondary")
    static let card = Color("Card")
    static let chipBackground = Color("ChipBackground")
    static let overlay = Color("Overlay")

    // MARK: - Text

    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textTertiary = Color("TextTertiary")

    // MARK: - Borders & Dividers

    static let border = Color("Border")

    // MARK: - Feedback

    static let success = Color("Success")
    static let warning = Color("Warning")
    static let destructive = Color("Destructive")
}

// MARK: - Shared proxy

extension ThemeManager {
    /// Weak-style global for SBColor accessors (set from app root).
    @MainActor
    static var sharedProxy: ThemeManager?
}

// MARK: - Previews

#if DEBUG
struct SBColor_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                ForEach(ThemePreset.allCases) { preset in
                    swatch(preset.displayName, preset.primary)
                }
                swatch("Background", SBColor.background)
                swatch("Card", SBColor.card)
            }
            .padding()
        }
        .background(SBColor.background)
    }

    private static func swatch(_ name: String, _ color: Color) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color)
                .frame(height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(SBColor.border, lineWidth: 1)
                )
            Text(name)
                .font(.caption2)
                .foregroundStyle(SBColor.textSecondary)
                .lineLimit(1)
        }
    }
}
#endif
