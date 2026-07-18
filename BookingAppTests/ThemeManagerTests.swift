//
//  ThemeManagerTests.swift
//  BookingAppTests
//
//  Theme + branding smoke tests for Iteration 7.
//

import Testing
@testable import BookingApp

struct ThemeManagerTests {

    @Test @MainActor
    func applyingPresetUpdatesBrandTheme() {
        let manager = ThemeManager()
        manager.apply(.forest)
        #expect(manager.preset == .forest)
        #expect(BrandTheme.current.preset == .forest)

        manager.apply(.violet)
        #expect(manager.preset == .violet)
    }

    @Test func allPresetsHaveDistinctNames() {
        let names = ThemePreset.allCases.map(\.displayName)
        #expect(Set(names).count == ThemePreset.allCases.count)
    }
}
