//
//  LoadingView.swift
//  SlotBook
//
//  Calm full-screen and inline loading indicators.
//

import SwiftUI

/// Centered loading state with optional message.
struct LoadingView: View {
    var message: String = "Loading…"
    var showsMessage: Bool = true

    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .controlSize(.regular)
                .tint(SBColor.primary)

            if showsMessage {
                Text(message)
                    .sbFontCaption()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SBColor.background.opacity(0.01)) // keeps hit testing stable
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

/// Compact inline spinner for toolbars or list rows.
struct InlineLoadingView: View {
    var body: some View {
        ProgressView()
            .controlSize(.small)
            .tint(SBColor.primary)
            .accessibilityLabel("Loading")
    }
}

// MARK: - Previews

#Preview("Loading — Light") {
    LoadingView(message: "Finding available slots…")
        .background(SBColor.background)
}

#Preview("Loading — Dark") {
    LoadingView()
        .background(SBColor.background)
        .preferredColorScheme(.dark)
}
