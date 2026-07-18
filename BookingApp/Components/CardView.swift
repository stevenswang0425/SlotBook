//
//  CardView.swift
//  SlotBook
//
//  Elevated surface container with consistent padding, radius, and shadow.
//

import SwiftUI

/// Reusable card container for grouping content on the calm SlotBook canvas.
///
/// ```swift
/// CardView {
///     Text("Hello")
/// }
/// ```
struct CardView<Content: View>: View {
    var padding: CGFloat = Spacing.md
    var cornerRadius: CGFloat = Radius.lg
    var showsShadow: Bool = true
    var showsBorder: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(
                    cornerRadius: cornerRadius * BrandTheme.current.cornerRadiusScale,
                    style: .continuous
                )
                .fill(SBColor.card)
            )
            .overlay {
                if showsBorder {
                    RoundedRectangle(
                        cornerRadius: cornerRadius * BrandTheme.current.cornerRadiusScale,
                        style: .continuous
                    )
                    .stroke(SBColor.border, lineWidth: 1)
                }
            }
            .modifier(ConditionalCardShadow(enabled: showsShadow))
    }
}

/// Applies card shadow only when requested (avoids shadow on dense lists if needed).
private struct ConditionalCardShadow: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.sbCardShadow()
        } else {
            content
        }
    }
}

// MARK: - Previews

#Preview("Card — Light") {
    VStack(spacing: Spacing.md) {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Morning Flow Yoga")
                    .sbFontHeadline()
                Text("A gentle start to your day with breath and movement.")
                    .sbFontBody()
            }
        }

        CardView(showsShadow: false, showsBorder: true) {
            Text("Border-only card")
                .sbFontSubheadline()
        }
    }
    .padding(Spacing.xl)
    .background(SBColor.background)
}

#Preview("Card — Dark") {
    CardView {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Evening Sauna")
                .sbFontHeadline()
            Text("45 min · $28")
                .sbFontCaption()
        }
    }
    .padding(Spacing.xl)
    .background(SBColor.background)
    .preferredColorScheme(.dark)
}
