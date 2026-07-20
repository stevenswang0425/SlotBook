//
//  ClubFilterBar.swift
//  SlotBook
//
//  Horizontal discovery filters for badminton clubs.
//

import SwiftUI

struct ClubFilterBar: View {
    let filters: [ClubDiscoveryFilter]
    let selected: ClubDiscoveryFilter
    let onSelect: (ClubDiscoveryFilter) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(filters) { filter in
                    SlotChip(
                        title: filter.displayName,
                        isSelected: filter == selected,
                        icon: filter.systemImage,
                        action: { onSelect(filter) }
                    )
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.xxs)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Club filters")
    }
}

// MARK: - Previews

#Preview("Club filters — Light") {
    ClubFilterBar(
        filters: ClubDiscoveryFilter.allCases,
        selected: .indoor,
        onSelect: { _ in }
    )
    .padding(.vertical)
    .background(SBColor.background)
    .themeManager(ThemeManager())
}

#Preview("Club filters — Dark") {
    ClubFilterBar(
        filters: ClubDiscoveryFilter.allCases,
        selected: .withCoaching,
        onSelect: { _ in }
    )
    .padding(.vertical)
    .background(SBColor.background)
    .themeManager(ThemeManager())
    .preferredColorScheme(.dark)
}
