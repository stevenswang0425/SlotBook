//
//  PrimaryButton.swift
//  SlotBook
//
//  Full-width primary CTA with loading and disabled states.
//  Fills use the active ThemeManager brand color.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.brandTheme) private var brandTheme

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .sbFontButton()
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(
                    cornerRadius: Radius.md * brandTheme.cornerRadiusScale,
                    style: .continuous
                )
                .fill(themeManager.preset.primary(for: colorScheme))
            )
        }
        .buttonStyle(SBPressableButtonStyle())
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

struct SecondaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.brandTheme) private var brandTheme

    var body: some View {
        Button(action: action) {
            Text(title)
                .sbFontButton()
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .foregroundStyle(themeManager.preset.primary(for: colorScheme))
                .background(
                    RoundedRectangle(
                        cornerRadius: Radius.md * brandTheme.cornerRadiusScale,
                        style: .continuous
                    )
                    .stroke(SBColor.border, lineWidth: 1.5)
                    .background(
                        RoundedRectangle(
                            cornerRadius: Radius.md * brandTheme.cornerRadiusScale,
                            style: .continuous
                        )
                        .fill(SBColor.card)
                    )
                )
        }
        .buttonStyle(SBPressableButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }
}

struct SBPressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Primary — Light") {
    let tm = ThemeManager()
    VStack(spacing: Spacing.md) {
        PrimaryButton(title: "Book slot") {}
        PrimaryButton(title: "Booking…", isLoading: true) {}
        SecondaryButton(title: "Maybe later") {}
    }
    .padding(Spacing.xl)
    .background(SBColor.background)
    .themeManager(tm)
}

#Preview("Primary — Violet Dark") {
    let tm = ThemeManager()
    tm.apply(.violet)
    return VStack(spacing: Spacing.md) {
        PrimaryButton(title: "Book slot") {}
        SecondaryButton(title: "Maybe later") {}
    }
    .padding(Spacing.xl)
    .background(SBColor.background)
    .themeManager(tm)
    .preferredColorScheme(.dark)
}
