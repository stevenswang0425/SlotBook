//
//  TimeSlotCell.swift
//  SlotBook
//
//  Single time-slot cell: Available (outline), Selected (filled), Booked (muted).
//

import SwiftUI

enum TimeSlotCellState: Equatable {
    case available
    case selected
    case booked
}

struct TimeSlotCell: View {
    let slot: TimeSlot
    let state: TimeSlotCellState
    var action: () -> Void

    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let primary = themeManager.preset.primary(for: colorScheme)

        Button(action: action) {
            VStack(spacing: 2) {
                Text(slot.startLabel())
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(primaryTextColor(primary))

                Text(slot.endLabel())
                    .font(.system(.caption2, design: .default).weight(.medium))
                    .foregroundStyle(secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(fillColor(primary))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(strokeColor(primary), lineWidth: state == .selected ? 0 : 1.25)
            )
        }
        .buttonStyle(SBPressableButtonStyle())
        .disabled(state == .booked)
        .animation(.spring(response: 0.28, dampingFraction: 0.84), value: state)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(accessibilityTraits)
        .accessibilityHint(state == .booked ? "Unavailable" : "Double tap to select")
    }

    private func primaryTextColor(_ primary: Color) -> Color {
        switch state {
        case .available: return SBColor.textPrimary
        case .selected: return .white
        case .booked: return SBColor.textTertiary
        }
    }

    private var secondaryTextColor: Color {
        switch state {
        case .available: return SBColor.textSecondary
        case .selected: return Color.white.opacity(0.85)
        case .booked: return SBColor.textTertiary.opacity(0.8)
        }
    }

    private func fillColor(_ primary: Color) -> Color {
        switch state {
        case .available: return SBColor.card
        case .selected: return primary
        case .booked: return SBColor.chipBackground
        }
    }

    private func strokeColor(_ primary: Color) -> Color {
        switch state {
        case .available: return primary.opacity(0.45)
        case .selected: return .clear
        case .booked: return SBColor.border
        }
    }

    private var accessibilityText: String {
        let range = slot.rangeLabel()
        switch state {
        case .available: return "\(range), available"
        case .selected: return "\(range), selected"
        case .booked: return "\(range), booked"
        }
    }

    private var accessibilityTraits: AccessibilityTraits {
        var traits: AccessibilityTraits = .isButton
        if state == .selected { traits.insert(.isSelected) }
        return traits
    }
}

#Preview("Slot States") {
    let base = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
    let end = Calendar.current.date(byAdding: .minute, value: 30, to: base)!
    let available = TimeSlot(id: UUID(), start: base, end: end, availability: .available)
    let booked = TimeSlot(id: UUID(), start: end, end: Calendar.current.date(byAdding: .minute, value: 30, to: end)!, availability: .booked)
    let tm = ThemeManager()

    return HStack(spacing: Spacing.sm) {
        TimeSlotCell(slot: available, state: .available) {}
        TimeSlotCell(slot: available, state: .selected) {}
        TimeSlotCell(slot: booked, state: .booked) {}
    }
    .padding()
    .background(SBColor.background)
    .themeManager(tm)
}
