//
//  EmptyStateView.swift
//  SlotBook
//
//  Reusable empty / error state with calm illustration treatment.
//

import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(themeManager.preset.primaryMuted(for: colorScheme).opacity(0.85))
                    .frame(width: 96, height: 96)

                Image(systemName: systemImage)
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(themeManager.preset.primary(for: colorScheme).opacity(0.85))
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityHidden(true)

            Text(title)
                .sbFontHeadline()
                .multilineTextAlignment(.center)

            Text(message)
                .sbFontBody()
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(.subheadline, design: .default).weight(.semibold))
                        .foregroundStyle(themeManager.preset.primary(for: colorScheme))
                }
                .padding(.top, Spacing.xs)
                .buttonStyle(SBPressableButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxxl)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Empty — Light") {
    EmptyStateView(
        systemImage: "calendar.badge.plus",
        title: "Nothing booked yet",
        message: "When you reserve a slot, it will show up here.",
        actionTitle: "Browse experiences",
        action: {}
    )
    .background(SBColor.background)
    .themeManager(ThemeManager())
}

#Preview("Empty — Dark") {
    EmptyStateView(
        systemImage: "wifi.exclamationmark",
        title: "Couldn't load",
        message: "Check your connection and try again.",
        actionTitle: "Try again",
        action: {}
    )
    .background(SBColor.background)
    .themeManager(ThemeManager())
    .preferredColorScheme(.dark)
}
