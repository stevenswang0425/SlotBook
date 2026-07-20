//
//  ClubCardView.swift
//  SlotBook
//
//  Discover card for a badminton club — calm hero, courts badge, address, summary.
//

import SwiftUI

struct ClubCardView: View {
    let club: BadmintonClub

    /// When true, uses a taller layout suited to single-column lists on larger phones.
    var expanded: Bool = false

    var body: some View {
        CardView(padding: 0, cornerRadius: Radius.lg) {
            VStack(alignment: .leading, spacing: 0) {
                hero

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(club.name)
                        .font(.system(.headline, design: .default))
                        .foregroundStyle(SBColor.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Label(club.shortAddressLabel, systemImage: "mappin.and.ellipse")
                        .font(.system(.caption, design: .default).weight(.medium))
                        .foregroundStyle(SBColor.textSecondary)
                        .lineLimit(1)

                    if expanded {
                        Text(club.cardSummary)
                            .font(.system(.subheadline, design: .default))
                            .foregroundStyle(SBColor.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                    }

                    HStack(spacing: Spacing.sm) {
                        courtsBadge

                        Spacer(minLength: 0)

                        Text(club.priceLabel)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(club.primaryColor.swiftUIColor)
                    }
                    .padding(.top, Spacing.xxs)
                }
                .padding(Spacing.md)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Opens club details")
    }

    // MARK: - Hero

    private var hero: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [
                    club.primaryColor.swiftUIColor.opacity(0.92),
                    club.primaryColor.swiftUIColor.opacity(0.55),
                    club.primaryColor.swiftUIColor.opacity(0.35),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft depth — no photos yet.
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 120, height: 120)
                .offset(x: 70, y: -24)

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 64, height: 64)
                .offset(x: -48, y: 40)

            Image(systemName: club.imageName)
                .font(.system(size: expanded ? 48 : 44, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.95))
                .symbolRenderingMode(.hierarchical)
                .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if club.hasCoaching {
                Text("Coaching")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.black.opacity(0.22))
                    )
                    .padding(Spacing.sm)
            }
        }
        .frame(height: expanded ? 148 : 132)
        .frame(maxWidth: .infinity)
        .clipped()
        .accessibilityHidden(true)
    }

    // MARK: - Courts badge

    private var courtsBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "sportscourt")
                .font(.system(size: 11, weight: .semibold))
            Text(club.courtsLabel)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(club.primaryColor.swiftUIColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(club.primaryColor.swiftUIColor.opacity(0.12))
        )
        .accessibilityLabel(club.courtsLabel)
    }

    private var accessibilitySummary: String {
        var parts = [
            club.name,
            club.locationLabel,
            club.courtsLabel,
            club.priceLabel,
        ]
        if club.hasCoaching { parts.append("Coaching available") }
        if club.isIndoor { parts.append("Indoor") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Previews

#Preview("Club Card") {
    ClubCardView(club: MockData.clubs[0], expanded: true)
        .padding()
        .background(SBColor.background)
}

#Preview("Club Cards — Grid") {
    LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 160), spacing: Spacing.md)],
        spacing: Spacing.md
    ) {
        ForEach(MockData.clubs) { club in
            ClubCardView(club: club)
        }
    }
    .padding()
    .background(SBColor.background)
}

#Preview("Club Cards — Dark") {
    VStack(spacing: Spacing.md) {
        ForEach(MockData.clubs) { club in
            ClubCardView(club: club, expanded: true)
        }
    }
    .padding()
    .background(SBColor.background)
    .preferredColorScheme(.dark)
}
