//
//  View+Typography.swift
//  SlotBook
//
//  Typography modifiers that map semantic roles to SF Pro styles.
//  Prefer these over raw `.font(...)` calls for consistent hierarchy.
//

import SwiftUI

// MARK: - Semantic Typography

extension View {
    /// Large marketing / logo wordmark (scales with Dynamic Type).
    func sbFontLogo() -> some View {
        self
            .font(.system(.title3, design: .rounded).weight(.semibold))
            .foregroundStyle(SBColor.textPrimary)
            .tracking(-0.3)
    }

    /// Screen or section title.
    func sbFontTitle() -> some View {
        self
            .font(.system(.title, design: .default).weight(.bold))
            .foregroundStyle(SBColor.textPrimary)
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    /// Card / list item title.
    func sbFontHeadline() -> some View {
        self
            .font(.system(.headline, design: .default))
            .foregroundStyle(SBColor.textPrimary)
    }

    /// Secondary emphasis (section labels, filter titles).
    func sbFontSubheadline() -> some View {
        self
            .font(.system(.subheadline, design: .default).weight(.medium))
            .foregroundStyle(SBColor.textPrimary)
    }

    /// Body copy.
    func sbFontBody() -> some View {
        self
            .font(.system(.subheadline, design: .default))
            .foregroundStyle(SBColor.textSecondary)
    }

    /// Supporting meta text (duration, price, location).
    func sbFontCaption() -> some View {
        self
            .font(.system(.caption, design: .default))
            .foregroundStyle(SBColor.textSecondary)
    }

    /// Small labels on chips and badges.
    func sbFontChip() -> some View {
        self
            .font(.system(.subheadline, design: .default).weight(.medium))
    }

    /// Primary button label.
    func sbFontButton() -> some View {
        self
            .font(.system(.body, design: .default).weight(.semibold))
    }
}

// MARK: - Preview

#if DEBUG
struct Typography_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("SlotBook").sbFontLogo()
            Text("Find your next slot").sbFontTitle()
            Text("Morning Flow Yoga").sbFontHeadline()
            Text("Section").sbFontSubheadline()
            Text("A calm 60-minute session with soft lighting and guided breathwork.")
                .sbFontBody()
            Text("45 min · $32").sbFontCaption()
            Text("Wellness").sbFontChip()
            Text("Book now").sbFontButton()
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SBColor.background)
        .previewDisplayName("Typography")

        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("SlotBook").sbFontLogo()
            Text("Find your next slot").sbFontTitle()
            Text("Morning Flow Yoga").sbFontHeadline()
            Text("45 min · $32").sbFontCaption()
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SBColor.background)
        .preferredColorScheme(.dark)
        .previewDisplayName("Typography Dark")
    }
}
#endif
