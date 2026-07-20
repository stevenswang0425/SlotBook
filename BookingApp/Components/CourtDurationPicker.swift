//
//  CourtDurationPicker.swift
//  SlotBook
//
//  Calm segmented duration control: 45 / 60 / 90 minutes.
//

import SwiftUI

struct CourtDurationPicker: View {
    let selection: CourtBookingDuration
    let onSelect: (CourtBookingDuration) -> Void

    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let primary = themeManager.primary(for: colorScheme)

        HStack(spacing: Spacing.xs) {
            ForEach(CourtBookingDuration.allCases) { duration in
                let isSelected = duration == selection
                Button {
                    onSelect(duration)
                } label: {
                    Text(duration.label)
                        .font(.system(.subheadline, design: .default).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .foregroundStyle(isSelected ? Color.white : SBColor.textSecondary)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                .fill(isSelected ? primary : SBColor.chipBackground)
                        )
                }
                .buttonStyle(SBPressableButtonStyle())
                .accessibilityLabel(duration.accessibilityLabel)
                .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .fill(SBColor.card)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                        .stroke(SBColor.border, lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.86), value: selection)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Duration")
    }
}

#Preview("Duration — Light") {
    CourtDurationPicker(selection: .sixty, onSelect: { _ in })
        .padding()
        .background(SBColor.background)
        .themeManager(ThemeManager())
}

#Preview("Duration — Dark") {
    CourtDurationPicker(selection: .ninety, onSelect: { _ in })
        .padding()
        .background(SBColor.background)
        .themeManager(ThemeManager())
        .preferredColorScheme(.dark)
}
