//
//  HomeView.swift
//  SlotBook
//
//  Items list: logo, real-time search, filter chips, responsive grid,
//  skeleton loading, pull-to-refresh, and navigation to item detail.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.brandTheme) private var brandTheme
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.repositories) private var repositories
    @State private var viewModel: HomeViewModel?

    /// Responsive grid: adapts column count on wider devices.
    private let columns = [
        GridItem(.adaptive(minimum: 156, maximum: 280), spacing: Spacing.md),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                SBColor.background
                    .ignoresSafeArea()

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
                prompt: "Search items"
            )
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
            }
            .task {
                if viewModel == nil {
                    viewModel = HomeViewModel(itemRepository: repositories.items)
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
            Image(systemName: brandTheme.logoSymbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(themeManager.preset.primary(for: colorScheme))
                .symbolRenderingMode(.hierarchical)

            Text(brandTheme.appName)
                .sbFontLogo()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ viewModel: HomeViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                CategoryFilterBar(
                    categories: viewModel.categories,
                    selected: viewModel.selectedCategory,
                    onSelect: { category in
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                            viewModel.selectCategory(category)
                        }
                    }
                )
                .padding(.top, Spacing.xs)

                if viewModel.showsSkeleton {
                    skeletonGrid
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else if let error = viewModel.loadError {
                    EmptyStateView(
                        systemImage: "wifi.exclamationmark",
                        title: "Couldn't load experiences",
                        message: error,
                        actionTitle: "Try again",
                        action: {
                            Task { await viewModel.refresh() }
                        }
                    )
                    .padding(.top, Spacing.xxl)
                    .transition(.opacity)
                } else if viewModel.isEmpty {
                    emptyState(viewModel)
                        .padding(.top, Spacing.xxl)
                        .transition(.opacity)
                } else {
                    itemGrid(viewModel)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.bottom, Spacing.xxl)
            .animation(.easeInOut(duration: 0.28), value: viewModel.selectedCategory)
            .animation(.easeInOut(duration: 0.28), value: viewModel.searchText)
            .animation(.easeInOut(duration: 0.35), value: viewModel.showsSkeleton)
            .animation(.easeInOut(duration: 0.28), value: viewModel.isEmpty)
        }
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Grids

    private func itemGrid(_ viewModel: HomeViewModel) -> some View {
        LazyVGrid(columns: columns, spacing: Spacing.md) {
            ForEach(viewModel.filteredItems) { item in
                NavigationLink(value: item) {
                    ItemCardView(item: item)
                }
                .buttonStyle(CardPressStyle())
                .accessibilityHint("Opens details and available times")
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96)),
                        removal: .opacity
                    )
                )
            }
        }
        .padding(.horizontal, Spacing.xl)
    }

    private var skeletonGrid: some View {
        LazyVGrid(columns: columns, spacing: Spacing.md) {
            ForEach(0..<4, id: \.self) { _ in
                ItemCardSkeleton()
            }
        }
        .padding(.horizontal, Spacing.xl)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading experiences")
    }

    // MARK: - Empty

    private func emptyState(_ viewModel: HomeViewModel) -> some View {
        EmptyStateView(
            systemImage: "magnifyingglass",
            title: "No matches",
            message: "Try another category or clear your search.",
            actionTitle: "Clear filters",
            action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.clearFilters()
                }
            }
        )
        .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - Card press style

/// Subtle scale on press for navigable cards.
private struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.16), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Home — Light") {
    HomeView()
        .themeManager(ThemeManager())
        .repositories(.makeDefault())
}

#Preview("Home — Dark") {
    HomeView()
        .themeManager(ThemeManager())
        .repositories(.makeDefault())
        .preferredColorScheme(.dark)
}
