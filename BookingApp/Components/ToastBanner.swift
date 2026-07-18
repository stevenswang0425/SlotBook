//
//  ToastBanner.swift
//  SlotBook
//
//  Ephemeral feedback banner (success / warning / info).
//

import SwiftUI

enum ToastBannerStyle: Equatable {
    case success
    case warning
    case info

    var systemImage: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .success: return SBColor.success
        case .warning: return SBColor.warning
        case .info: return SBColor.primary
        }
    }
}

struct ToastBanner: View {
    let message: String
    var style: ToastBannerStyle = .success

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: style.systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(style.tint)
                .accessibilityHidden(true)

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SBColor.textPrimary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .fill(SBColor.card)
                .sbRaisedShadow()
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .stroke(SBColor.border, lineWidth: 1)
        )
        .padding(.horizontal, Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityLabel(message)
    }
}

// MARK: - Previews

#Preview("Toast styles") {
    VStack(spacing: Spacing.md) {
        Spacer()
        ToastBanner(message: "Booking cancelled · slot released", style: .success)
        ToastBanner(message: "Someone just booked this slot", style: .warning)
        ToastBanner(message: "A slot just opened up", style: .info)
            .padding(.bottom, Spacing.xl)
    }
    .background(SBColor.background)
}

#Preview("Toast — Dark") {
    VStack {
        Spacer()
        ToastBanner(message: "Someone just booked this slot", style: .warning)
            .padding(.bottom, Spacing.xl)
    }
    .background(SBColor.background)
    .preferredColorScheme(.dark)
}
