//
//  BookingSummaryCard.swift
//  SlotBook
//
//  Shared summary card for item + time across booking steps.
//

import SwiftUI

struct BookingSummaryCard: View {
    let item: Item
    let slot: TimeSlot
    let date: Date
    var durationLabel: String

    var body: some View {
        CardView(showsShadow: true, showsBorder: false) {
            HStack(alignment: .top, spacing: Spacing.md) {
                // Mini art
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    item.color.swiftUIColor.opacity(0.9),
                                    item.color.swiftUIColor.opacity(0.5),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Image(systemName: item.imageName)
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(.white)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(item.name)
                        .sbFontHeadline()
                        .lineLimit(2)

                    Text(dateLabel)
                        .sbFontCaption()

                    Text("\(slot.rangeLabel()) · \(durationLabel)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SBColor.primary)
                }

                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(dateLabel), \(slot.rangeLabel()), \(durationLabel)")
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Previews

#Preview("Summary — Light") {
    let item = MockItems.catalog[1]
    let day = Calendar.current.startOfDay(for: Date())
    let slot = MockSlots.slots(for: day, itemID: item.id).first { $0.isAvailable }!

    BookingSummaryCard(item: item, slot: slot, date: day, durationLabel: "30 min")
        .padding()
        .background(SBColor.background)
}

#Preview("Summary — Dark") {
    let item = MockItems.catalog[0]
    let day = Calendar.current.startOfDay(for: Date())
    let slot = MockSlots.slots(for: day, itemID: item.id).first { $0.isAvailable }!

    BookingSummaryCard(item: item, slot: slot, date: day, durationLabel: "30 min")
        .padding()
        .background(SBColor.background)
        .preferredColorScheme(.dark)
}
