//
//  BookingStatusBadge.swift
//  SlotBook
//
//  Soft status chip for booking cards.
//

import SwiftUI

struct BookingStatusBadge: View {
    let status: BookingDisplayStatus

    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(status.title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(background)
            )
            .accessibilityLabel(status.title)
    }

    private var foreground: Color {
        switch status {
        case .upcoming: return themeManager.primary(for: colorScheme)
        case .completed: return SBColor.success
        case .cancelled: return SBColor.textSecondary
        }
    }

    private var background: Color {
        switch status {
        case .upcoming: return themeManager.primaryMuted(for: colorScheme)
        case .completed: return SBColor.success.opacity(0.14)
        case .cancelled: return SBColor.chipBackground
        }
    }
}

// MARK: - Previews

#Preview("Status Badges") {
    HStack(spacing: Spacing.sm) {
        BookingStatusBadge(status: .upcoming)
        BookingStatusBadge(status: .completed)
        BookingStatusBadge(status: .cancelled)
    }
    .padding()
    .background(SBColor.background)
}
