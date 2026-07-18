//
//  HomeViewModel.swift
//  SlotBook
//
//  Items list: search, filters, skeleton load, pull-to-refresh, error state.
//  Loads catalog via ItemRepository (mock today → Supabase tomorrow).
//

import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {

    var searchText: String = ""
    var selectedCategory: ItemCategory = .all
    var isLoading: Bool = false
    private(set) var hasLoadedOnce: Bool = false
    private(set) var items: [Item] = []
    var loadError: String?

    let categories: [ItemCategory] = ItemCategory.allCases

    /// Injected repository — swap implementation at the composition root.
    private let itemRepository: any ItemRepository

    init(itemRepository: any ItemRepository = MockItemRepository()) {
        self.itemRepository = itemRepository
    }

    var filteredItems: [Item] {
        items.filter { item in
            let matchesCategory =
                selectedCategory == .all || item.category == selectedCategory

            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { return matchesCategory }

            let matchesSearch =
                item.name.localizedCaseInsensitiveContains(query)
                || item.description.localizedCaseInsensitiveContains(query)
                || item.category.displayName.localizedCaseInsensitiveContains(query)

            return matchesCategory && matchesSearch
        }
    }

    var isEmpty: Bool {
        hasLoadedOnce && !isLoading && filteredItems.isEmpty && loadError == nil
    }

    var showsSkeleton: Bool {
        isLoading && !hasLoadedOnce
    }

    func load() async {
        guard !hasLoadedOnce else { return }
        await fetch()
    }

    func refresh() async {
        await fetch()
    }

    func clearFilters() {
        searchText = ""
        selectedCategory = .all
        HapticFeedback.lightImpact()
    }

    func selectCategory(_ category: ItemCategory) {
        selectedCategory = category
        HapticFeedback.selection()
    }

    private func fetch() async {
        isLoading = true
        loadError = nil
        do {
            // Repository seam — MockItemRepository today; SupabaseItemRepository later.
            items = try await itemRepository.fetchItems()
            hasLoadedOnce = true
        } catch {
            loadError = error.localizedDescription
            // Keep stale items if we already had a successful load.
            if !hasLoadedOnce {
                items = []
            }
        }
        isLoading = false
    }
}
