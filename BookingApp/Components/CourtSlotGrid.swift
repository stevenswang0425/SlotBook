//
//  CourtSlotGrid.swift
//  SlotBook
//
//  Player-facing start-time grid. No court numbers — ever.
//  Available = soft success green; Booked = muted gray; Selected = club primary.
//

import SwiftUI

enum CourtSlotCellState: Equatable {
    case available
    case selected
    case booked
}

struct CourtSlotGrid: View {
    let options: [ClubStartOption]
    let selectedID: UUID?
    let isLoading: Bool
    let onSelect: (ClubStartOption) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 104, maximum: 160), spacing: Spacing.sm),
    ]

    var body: some View {
        Group {
            if isLoading {
                skeleton
            } else if options.isEmpty {
                Text("No times for this day.")
                    .sbFontCaption()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LazyVGrid(columns: columns, spacing: Spacing.sm) {
                    ForEach(options) { option in
                        CourtSlotCell(
                            option: option,
                            state: state(for: option),
                            action: {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                                    onSelect(option)
                                }
                            }
                        )
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isLoading)
        .animation(.easeInOut(duration: 0.25), value: options.map(\.id))
    }

    private func state(for option: ClubStartOption) -> CourtSlotCellState {
        if !option.isAvailable { return .booked }
        if option.id == selectedID { return .selected }
        return .available
    }

    private var skeleton: some View {
        LazyVGrid(columns: columns, spacing: Spacing.sm) {
            ForEach(0..<9, id: \.self) { _ in
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(SBColor.chipBackground)
                    .frame(height: 64)
            }
        }
        .redacted(reason: .placeholder)
        .accessibilityLabel("Loading times")
    }
}

// MARK: - Cell

struct CourtSlotCell: View {
    let option: ClubStartOption
    let state: CourtSlotCellState
    var action: () -> Void

    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    /// Soft success green for available slots (calm, scannable).
    private var availableAccent: Color {
        SBColor.success
    }

    private var primary: Color {
        themeManager.primary(for: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(option.startLabel())
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(primaryTextColor)

                Text(option.endLabel())
                    .font(.system(.caption2, design: .default).weight(.medium))
                    .foregroundStyle(secondaryTextColor)

                if state == .booked {
                    Text("Booked")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(SBColor.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(fillColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(strokeColor, lineWidth: state == .selected ? 0 : 1.25)
            )
        }
        .buttonStyle(SBPressableButtonStyle())
        .disabled(state == .booked)
        .animation(.spring(response: 0.28, dampingFraction: 0.84), value: state)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(accessibilityTraits)
        .accessibilityHint(state == .booked ? "Unavailable" : "Double tap to book this time")
    }

    private var primaryTextColor: Color {
        switch state {
        case .available: return SBColor.textPrimary
        case .selected: return .white
        case .booked: return SBColor.textTertiary
        }
    }

    private var secondaryTextColor: Color {
        switch state {
        case .available: return SBColor.textSecondary
        case .selected: return Color.white.opacity(0.88)
        case .booked: return SBColor.textTertiary.opacity(0.85)
        }
    }

    private var fillColor: Color {
        switch state {
        case .available: return availableAccent.opacity(colorScheme == .dark ? 0.16 : 0.10)
        case .selected: return primary
        case .booked: return SBColor.chipBackground
        }
    }

    private var strokeColor: Color {
        switch state {
        case .available: return availableAccent.opacity(0.45)
        case .selected: return .clear
        case .booked: return SBColor.border
        }
    }

    private var accessibilityText: String {
        let range = option.rangeLabel()
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

// MARK: - Previews

#Preview("Court slot grid") {
    let day = Calendar.current.startOfDay(for: Date().addingTimeInterval(86_400))
    let options = MockData.findAvailableSlots(
        clubId: MockData.torontoClubId,
        date: day,
        durationMinutes: 60
    )

    return ScrollView {
        CourtSlotGrid(
            options: options,
            selectedID: options.first(where: \.isAvailable)?.id,
            isLoading: false,
            onSelect: { _ in }
        )
        .padding()
    }
    .background(SBColor.background)
    .themeManager(ThemeManager())
}

#Preview("Cell states") {
    let start = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!
    let end = Calendar.current.date(byAdding: .minute, value: 60, to: start)!
    let available = ClubStartOption(
        id: UUID(),
        clubId: MockData.torontoClubId,
        start: start,
        end: end,
        durationMinutes: 60,
        isAvailable: true,
        assignedCourtId: UUID()
    )
    let booked = ClubStartOption(
        id: UUID(),
        clubId: MockData.torontoClubId,
        start: end,
        end: Calendar.current.date(byAdding: .minute, value: 60, to: end)!,
        durationMinutes: 60,
        isAvailable: false,
        assignedCourtId: nil
    )

    return HStack(spacing: Spacing.sm) {
        CourtSlotCell(option: available, state: .available) {}
        CourtSlotCell(option: available, state: .selected) {}
        CourtSlotCell(option: booked, state: .booked) {}
    }
    .padding()
    .background(SBColor.background)
    .themeManager(ThemeManager())
}
