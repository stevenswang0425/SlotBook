//
//  DiscoverViewModel.swift
//  SlotBook
//
//  Discover tab: load badminton clubs, search, filter chips, refresh.
//  (Club discovery VM — marketplace catalog remains HomeViewModel.)
//

import Foundation
import Observation

@Observable
@MainActor
final class DiscoverViewModel {
    var searchText: String = ""
    var selectedFilter: ClubDiscoveryFilter = .all
    var isLoading: Bool = false
    private(set) var hasLoadedOnce: Bool = false
    private(set) var clubs: [BadmintonClub] = []
    var loadError: String?

    let filters: [ClubDiscoveryFilter] = ClubDiscoveryFilter.allCases

    private let clubRepository: any ClubRepository

    init(clubRepository: any ClubRepository = MockClubRepository()) {
        self.clubRepository = clubRepository
    }

    // MARK: - Derived

    var filteredClubs: [BadmintonClub] {
        clubs.filter { club in
            guard club.matches(filter: selectedFilter) else { return false }

            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { return true }

            return club.name.localizedCaseInsensitiveContains(query)
                || club.city.localizedCaseInsensitiveContains(query)
                || club.address.localizedCaseInsensitiveContains(query)
                || club.tagline.localizedCaseInsensitiveContains(query)
                || club.description.localizedCaseInsensitiveContains(query)
        }
    }

    var isEmpty: Bool {
        hasLoadedOnce && !isLoading && filteredClubs.isEmpty && loadError == nil
    }

    var showsSkeleton: Bool {
        isLoading && !hasLoadedOnce
    }

    /// True when empty is due to search/filter rather than zero catalog.
    var isFilterEmpty: Bool {
        isEmpty && (!searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || selectedFilter != .all)
    }

    var resultsCountLabel: String {
        let count = filteredClubs.count
        if count == 0 { return "" }
        return count == 1 ? "1 club" : "\(count) clubs"
    }

    // MARK: - Actions

    func selectFilter(_ filter: ClubDiscoveryFilter) {
        guard selectedFilter != filter else { return }
        selectedFilter = filter
        HapticFeedback.selection()
    }

    func clearFilters() {
        searchText = ""
        selectedFilter = .all
        HapticFeedback.lightImpact()
    }

    func load() async {
        guard !hasLoadedOnce else { return }
        await fetch()
    }

    func refresh() async {
        await fetch()
    }

    private func fetch() async {
        isLoading = true
        loadError = nil
        do {
            // FUTURE: SupabaseClubRepository.fetchClubs()
            clubs = try await clubRepository.fetchClubs()
            hasLoadedOnce = true
        } catch {
            loadError = error.localizedDescription
            if !hasLoadedOnce { clubs = [] }
        }
        isLoading = false
    }
}
