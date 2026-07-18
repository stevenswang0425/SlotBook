//
//  ItemCardView.swift
//  SlotBook
//
//  Card cell for an item in the Home grid.
//  Layout: image → category badge → title → description.
//

import SwiftUI

struct ItemCardView: View {
    let item: Item

    var body: some View {
        CardView(padding: 0, cornerRadius: Radius.lg) {
            VStack(alignment: .leading, spacing: 0) {
                artwork

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    CategoryBadge(
                        category: item.category,
                        accent: item.color.swiftUIColor
                    )

                    Text(item.name)
                        .sbFontHeadline()
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(item.description)
                        .sbFontCaption()
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Spacing.md)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(item.category.displayName). \(item.description)")
        .accessibilityHint("Opens item details")
    }

    // MARK: - Artwork

    private var artwork: some View {
        ZStack {
            LinearGradient(
                colors: [
                    item.color.swiftUIColor.opacity(0.85),
                    item.color.swiftUIColor.opacity(0.55),
                    item.color.swiftUIColor.opacity(0.35),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft decorative orb for depth without clutter
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 90, height: 90)
                .blur(radius: 2)
                .offset(x: 48, y: -28)

            Image(systemName: item.imageName)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.white.opacity(0.95))
                .symbolRenderingMode(.hierarchical)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        }
        .frame(height: 128)
        .frame(maxWidth: .infinity)
        .clipped()
    }
}

// MARK: - Previews

#Preview("Item Card — Light") {
    ItemCardView(item: MockItems.catalog[1])
        .frame(width: 180)
        .padding()
        .background(SBColor.background)
}

#Preview("Item Card — Dark") {
    ItemCardView(item: MockItems.catalog[0])
        .frame(width: 180)
        .padding()
        .background(SBColor.background)
        .preferredColorScheme(.dark)
}

#Preview("Card Grid") {
    LazyVGrid(
        columns: [GridItem(.flexible()), GridItem(.flexible())],
        spacing: Spacing.md
    ) {
        ForEach(MockItems.catalog.prefix(4)) { item in
            ItemCardView(item: item)
        }
    }
    .padding()
    .background(SBColor.background)
}
