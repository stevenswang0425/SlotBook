//
//  BookingStatusBadge.swift
//  SlotBook
//
//  Soft status chip for booking cards.
//

import SwiftUI

struct BookingStatusBadge: View {
    let status: BookingDisplayStatus

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
        case .upcoming: return SBColor.primary
        case .completed: return SBColor.success
        case .cancelled: return SBColor.textSecondary
        }
    }

    private var background: Color {
        switch status {
        case .upcoming: return SBColor.primaryMuted
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
