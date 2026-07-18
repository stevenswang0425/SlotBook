//
//  TimeSlotGrid.swift
//  SlotBook
//
//  Responsive grid of time slots for the selected day.
//

import SwiftUI

struct TimeSlotGrid: View {
    let slots: [TimeSlot]
    let selectedSlotID: UUID?
    let onSelect: (TimeSlot) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 96, maximum: 140), spacing: Spacing.sm),
    ]

    var body: some View {
        if slots.isEmpty {
            Text("No times available for this day.")
                .sbFontCaption()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.xl)
        } else {
            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(slots) { slot in
                    TimeSlotCell(
                        slot: slot,
                        state: cellState(for: slot),
                        action: {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                                onSelect(slot)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, Spacing.xl)
        }
    }

    private func cellState(for slot: TimeSlot) -> TimeSlotCellState {
        if slot.isBooked { return .booked }
        if slot.id == selectedSlotID { return .selected }
        return .available
    }
}

// MARK: - Previews

#Preview("Time Slot Grid — Light") {
    let item = MockItems.catalog[0]
    let day = Calendar.current.startOfDay(for: Date())
    let slots = MockSlots.slots(for: day, itemID: item.id)

    ScrollView {
        TimeSlotGrid(
            slots: slots,
            selectedSlotID: slots.first(where: \.isAvailable)?.id,
            onSelect: { _ in }
        )
        .padding(.vertical)
    }
    .background(SBColor.background)
}

#Preview("Time Slot Grid — Dark") {
    let item = MockItems.catalog[1]
    let day = Calendar.current.startOfDay(for: Date())
    let slots = MockSlots.slots(for: day, itemID: item.id)

    ScrollView {
        TimeSlotGrid(
            slots: slots,
            selectedSlotID: nil,
            onSelect: { _ in }
        )
        .padding(.vertical)
    }
    .background(SBColor.background)
    .preferredColorScheme(.dark)
}
