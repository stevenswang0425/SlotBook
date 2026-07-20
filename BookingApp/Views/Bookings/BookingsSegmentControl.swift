//
//  BookingsSegmentControl.swift
//  SlotBook
//
//  Calm two-segment control for Upcoming / Past.
//

import SwiftUI

struct BookingsSegmentControl: View {
    @Binding var selection: BookingsSegment
    var upcomingCount: Int = 0
    var pastCount: Int = 0

    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            ForEach(BookingsSegment.allCases) { segment in
                segmentButton(segment)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(SBColor.chipBackground)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Booking filters")
    }

    private func segmentButton(_ segment: BookingsSegment) -> some View {
        let isSelected = selection == segment
        let count = segment == .upcoming ? upcomingCount : pastCount
        let primary = themeManager.primary(for: colorScheme)
        let muted = themeManager.primaryMuted(for: colorScheme)

        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                selection = segment
            }
        } label: {
            HStack(spacing: 6) {
                Text(segment.title)
                    .font(.system(size: 14, weight: .semibold))

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? primary : SBColor.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? muted : SBColor.card.opacity(0.7))
                        )
                }
            }
            .foregroundStyle(isSelected ? SBColor.textPrimary : SBColor.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: Radius.sm + 2, style: .continuous)
                    .fill(isSelected ? SBColor.card : Color.clear)
                    .sbCardShadow()
                    .opacity(isSelected ? 1 : 0)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .accessibilityLabel("\(segment.title), \(count) bookings")
    }
}

// MARK: - Previews

#Preview("Segments — Light") {
    @Previewable @State var selection: BookingsSegment = .upcoming

    BookingsSegmentControl(selection: $selection, upcomingCount: 2, pastCount: 1)
        .padding()
        .background(SBColor.background)
}

#Preview("Segments — Dark") {
    @Previewable @State var selection: BookingsSegment = .past

    BookingsSegmentControl(selection: $selection, upcomingCount: 0, pastCount: 3)
        .padding()
        .background(SBColor.background)
        .preferredColorScheme(.dark)
}
