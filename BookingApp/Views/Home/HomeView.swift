//
//  HomeView.swift
//  SlotBook
//
//  Discover — badminton club list with search, filters, grid, empty states.
//  Iteration 2: filter chips + richer cards + polished empty / loading UX.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.brandTheme) private var brandTheme
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.repositories) private var repositories

    @State private var viewModel: DiscoverViewModel?

    /// Adaptive grid — two columns on phone portrait, wider cards on iPad.
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 420), spacing: Spacing.md),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                SBColor.background.ignoresSafeArea()

                if let viewModel {
                    content(viewModel)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    logo
                }
            }
            .searchable(
                text: searchBinding,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by name or address"
            )
            .navigationDestination(for: BadmintonClub.self) { club in
                // Pass club into detail VM (repository from environment).
                ClubDetailView(club: club)
            }
            .task {
                if viewModel == nil {
                    viewModel = DiscoverViewModel(clubRepository: repositories.clubs)
                }
                await viewModel?.load()
            }
        }
    }

    private var searchBinding: Binding<String> {
        Binding(
            get: { viewModel?.searchText ?? "" },
            set: { viewModel?.searchText = $0 }
        )
    }

    // MARK: - Logo

    private var logo: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "figure.badminton")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(themeManager.primary(for: colorScheme))
                .symbolRenderingMode(.hierarchical)

            Text(brandTheme.appName)
                .sbFontLogo()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ viewModel: DiscoverViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                intro

                ClubFilterBar(
                    filters: viewModel.filters,
                    selected: viewModel.selectedFilter,
                    onSelect: { viewModel.selectFilter($0) }
                )
                .animation(.easeInOut(duration: 0.2), value: viewModel.selectedFilter)

                if viewModel.showsSkeleton {
                    skeletonGrid
                        .transition(.opacity)
                } else if let error = viewModel.loadError {
                    EmptyStateView(
                        systemImage: "wifi.exclamationmark",
                        title: "Couldn't load clubs",
                        message: error,
                        actionTitle: "Try again",
                        action: { Task { await viewModel.refresh() } }
                    )
                    .padding(.top, Spacing.lg)
                } else if viewModel.isEmpty {
                    EmptyStateView(
                        systemImage: viewModel.isFilterEmpty
                            ? "magnifyingglass"
                            : "sportscourt",
                        title: "No clubs found",
                        message: viewModel.isFilterEmpty
                            ? "Try another name, address, or clear filters."
                            : "Clubs will appear here when available.",
                        actionTitle: viewModel.isFilterEmpty ? "Clear filters" : nil,
                        action: viewModel.isFilterEmpty
                            ? { viewModel.clearFilters() }
                            : nil
                    )
                    .padding(.top, Spacing.lg)
                } else {
                    if !viewModel.resultsCountLabel.isEmpty {
                        Text(viewModel.resultsCountLabel)
                            .sbFontCaption()
                            .padding(.horizontal, Spacing.xl)
                            .accessibilityLabel(viewModel.resultsCountLabel)
                    }
                    clubGrid(viewModel)
                }
            }
            .padding(.bottom, Spacing.xxl)
            .animation(.easeInOut(duration: 0.28), value: viewModel.searchText)
            .animation(.easeInOut(duration: 0.28), value: viewModel.selectedFilter)
            .animation(.easeInOut(duration: 0.35), value: viewModel.showsSkeleton)
        }
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text("Discover clubs")
                .sbFontHeadline()
            Text("Book badminton courts across the GTA.")
                .sbFontCaption()
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.sm)
        .accessibilityElement(children: .combine)
    }

    private func clubGrid(_ viewModel: DiscoverViewModel) -> some View {
        LazyVGrid(columns: columns, spacing: Spacing.md) {
            ForEach(viewModel.filteredClubs) { club in
                NavigationLink(value: club) {
                    // Expanded body when the adaptive column is wide enough feels roomier.
                    ClubCardView(club: club, expanded: true)
                }
                .buttonStyle(DiscoverCardPressStyle())
            }
        }
        .padding(.horizontal, Spacing.xl)
    }

    private var skeletonGrid: some View {
        LazyVGrid(columns: columns, spacing: Spacing.md) {
            ForEach(0..<3, id: \.self) { _ in
                ClubCardSkeleton()
            }
        }
        .padding(.horizontal, Spacing.xl)
        .accessibilityLabel("Loading clubs")
    }
}

// MARK: - Skeleton

private struct ClubCardSkeleton: View {
    var body: some View {
        CardView(padding: 0, cornerRadius: Radius.lg) {
            VStack(alignment: .leading, spacing: 0) {
                RoundedRectangle(cornerRadius: 0)
                    .fill(SBColor.chipBackground)
                    .frame(height: 148)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SBColor.chipBackground)
                        .frame(height: 16)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SBColor.chipBackground)
                        .frame(width: 140, height: 12)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SBColor.chipBackground)
                        .frame(height: 28)
                    HStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(SBColor.chipBackground)
                            .frame(width: 72, height: 22)
                        Spacer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(SBColor.chipBackground)
                            .frame(width: 48, height: 12)
                    }
                }
                .padding(Spacing.md)
            }
        }
        .redacted(reason: .placeholder)
    }
}

private struct DiscoverCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Discover — Light") {
    HomeView()
        .themeManager(ThemeManager())
        .repositories(.makeDefault())
}

#Preview("Discover — Dark") {
    HomeView()
        .themeManager(ThemeManager())
        .repositories(.makeDefault())
        .preferredColorScheme(.dark)
}
