//
//  CategoryFilterBar.swift
//  SlotBook
//
//  Horizontal scroll of category filter chips.
//

import SwiftUI

struct CategoryFilterBar: View {
    let categories: [ItemCategory]
    let selected: ItemCategory
    let onSelect: (ItemCategory) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(categories) { category in
                    SlotChip(
                        title: category.displayName,
                        isSelected: category == selected,
                        icon: category.systemImage,
                        action: { onSelect(category) }
                    )
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.xxs)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Categories")
    }
}

// MARK: - Previews

#Preview("Filters — Light") {
    CategoryFilterBar(
        categories: ItemCategory.allCases,
        selected: .wellness,
        onSelect: { _ in }
    )
    .padding(.vertical)
    .background(SBColor.background)
}

#Preview("Filters — Dark") {
    CategoryFilterBar(
        categories: ItemCategory.allCases,
        selected: .all,
        onSelect: { _ in }
    )
    .padding(.vertical)
    .background(SBColor.background)
    .preferredColorScheme(.dark)
}
