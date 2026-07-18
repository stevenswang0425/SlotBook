//
//  ItemCardSkeleton.swift
//  SlotBook
//
//  Shimmer-style placeholder used while the catalog is “fetching”.
//

import SwiftUI

/// Skeleton stand-in matching `ItemCardView` proportions.
struct ItemCardSkeleton: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        CardView(padding: 0, cornerRadius: Radius.lg) {
            VStack(alignment: .leading, spacing: 0) {
                shimmerBlock(height: 128)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    shimmerBlock(height: 14)
                        .frame(width: 48)
                        .clipShape(Capsule())

                    shimmerBlock(height: 16)
                        .frame(maxWidth: .infinity)

                    shimmerBlock(height: 12)
                        .frame(maxWidth: 120)
                }
                .padding(Spacing.md)
            }
        }
        .redacted(reason: .placeholder)
        .overlay {
            // Soft sliding highlight for a calm loading feel
            GeometryReader { geo in
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.35),
                        .clear,
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geo.size.width * 0.45)
                .offset(x: phase * geo.size.width)
                .blendMode(.plusLighter)
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            .allowsHitTesting(false)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                phase = 1.2
            }
        }
        .accessibilityLabel("Loading item")
    }

    private func shimmerBlock(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
            .fill(SBColor.chipBackground)
            .frame(height: height)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

#Preview("Skeleton — Light") {
    ItemCardSkeleton()
        .frame(width: 180)
        .padding()
        .background(SBColor.background)
}

#Preview("Skeleton — Dark") {
    ItemCardSkeleton()
        .frame(width: 180)
        .padding()
        .background(SBColor.background)
        .preferredColorScheme(.dark)
}
