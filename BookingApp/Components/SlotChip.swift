//
//  SlotChip.swift
//  SlotBook
//
//  Pill-shaped selectable chip for filters and time slots.
//

import SwiftUI

struct SlotChip: View {
    let title: String
    var isSelected: Bool = false
    var icon: String? = nil
    var action: (() -> Void)? = nil

    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    chipLabel
                }
                .buttonStyle(.plain)
            } else {
                chipLabel
            }
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private var chipLabel: some View {
        let primary = themeManager.preset.primary(for: colorScheme)
        let muted = themeManager.preset.primaryMuted(for: colorScheme)

        return HStack(spacing: Spacing.xxs) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
            }
            Text(title)
                .sbFontChip()
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .foregroundStyle(isSelected ? primary : SBColor.textSecondary)
        .background(
            Capsule(style: .continuous)
                .fill(isSelected ? muted : SBColor.chipBackground)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(isSelected ? primary.opacity(0.25) : Color.clear, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }
}

#Preview("Chips") {
    let tm = ThemeManager()
    HStack(spacing: Spacing.xs) {
        SlotChip(title: "All", isSelected: true) {}
        SlotChip(title: "Cafe", icon: "cup.and.saucer") {}
        SlotChip(title: "Wellness", icon: "leaf") {}
    }
    .padding()
    .background(SBColor.background)
    .themeManager(tm)
}
