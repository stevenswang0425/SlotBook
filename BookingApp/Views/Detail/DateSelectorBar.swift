//
//  DateSelectorBar.swift
//  SlotBook
//
//  Horizontal scroll of upcoming days for Item Detail.
//

import SwiftUI

struct DateSelectorBar: View {
    let days: [SelectableDay]
    let selectedDate: Date
    let onSelect: (Date) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(days) { day in
                        DayChip(
                            day: day,
                            isSelected: Calendar.current.isDate(day.date, inSameDayAs: selectedDate),
                            action: { onSelect(day.date) }
                        )
                        .id(day.id)
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.xxs)
            }
            .onAppear {
                proxy.scrollTo(selectedDate, anchor: .leading)
            }
            .onChange(of: selectedDate) { _, newValue in
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Select a date")
    }
}

// MARK: - Day chip

struct DayChip: View {
    let day: SelectableDay
    var isSelected: Bool
    var action: () -> Void

    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        // Respects club primary override when browsing a club.
        let primary = themeManager.primary(for: colorScheme)

        Button(action: action) {
            VStack(spacing: Spacing.xxs) {
                Text(day.weekdayLabel())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.9) : SBColor.textSecondary)

                Text(day.dayNumberLabel())
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? Color.white : SBColor.textPrimary)

                Text(day.monthLabel())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.85) : SBColor.textTertiary)
            }
            .frame(width: 64)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(isSelected ? primary : SBColor.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(isSelected ? Color.clear : SBColor.border, lineWidth: 1)
            )
            .sbCardShadow()
        }
        .buttonStyle(SBPressableButtonStyle())
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: isSelected)
        .accessibilityLabel(day.accessibilityLabel())
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

// MARK: - Previews

#Preview("Date Selector — Light") {
    DateSelectorBar(
        days: MockSlots.upcomingDays(count: 14),
        selectedDate: Calendar.current.startOfDay(for: Date()),
        onSelect: { _ in }
    )
    .padding(.vertical)
    .background(SBColor.background)
}

#Preview("Date Selector — Dark") {
    DateSelectorBar(
        days: MockSlots.upcomingDays(count: 14),
        selectedDate: Calendar.current.startOfDay(for: Date()),
        onSelect: { _ in }
    )
    .padding(.vertical)
    .background(SBColor.background)
    .preferredColorScheme(.dark)
}

#Preview("Day Chip States") {
    HStack(spacing: Spacing.sm) {
        DayChip(
            day: SelectableDay(date: Date()),
            isSelected: false,
            action: {}
        )
        DayChip(
            day: SelectableDay(date: Date()),
            isSelected: true,
            action: {}
        )
    }
    .padding()
    .background(SBColor.background)
}
