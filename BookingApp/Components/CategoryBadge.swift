//
//  CategoryBadge.swift
//  SlotBook
//
//  Compact category pill for item cards and detail headers.
//

import SwiftUI

/// Soft category label, tinted with the item’s accent color.
struct CategoryBadge: View {
    let category: ItemCategory
    var accent: Color = SBColor.primary

    var body: some View {
        HStack(spacing: 4) {
            if let icon = category.systemImage, category != .all {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(category.displayName)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(accent)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(accent.opacity(0.14))
        )
        .accessibilityLabel(category.displayName)
    }
}

// MARK: - Previews

#Preview("Badges — Light") {
    HStack(spacing: Spacing.xs) {
        CategoryBadge(category: .cafe, accent: ItemColor(r: 180, g: 120, b: 72).swiftUIColor)
        CategoryBadge(category: .wellness, accent: ItemColor(r: 72, g: 160, b: 132).swiftUIColor)
        CategoryBadge(category: .experiences, accent: ItemColor(r: 150, g: 100, b: 180).swiftUIColor)
    }
    .padding()
    .background(SBColor.background)
}

#Preview("Badges — Dark") {
    CategoryBadge(category: .service)
        .padding()
        .background(SBColor.background)
        .preferredColorScheme(.dark)
}
