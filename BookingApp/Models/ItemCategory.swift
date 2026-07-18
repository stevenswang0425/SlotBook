//
//  ItemCategory.swift
//  SlotBook
//
//  Categories used to filter items on Home.
//

import Foundation

/// High-level verticals for bookable experiences.
///
/// Filter chips: All · Cafe · Wellness · Service · Experiences
nonisolated enum ItemCategory: String, CaseIterable, Identifiable, Sendable, Hashable {
    case all
    case cafe
    case wellness
    case service
    case experiences

    var id: String { rawValue }

    /// User-facing label for chips and badges.
    var displayName: String {
        switch self {
        case .all: return "All"
        case .cafe: return "Cafe"
        case .wellness: return "Wellness"
        case .service: return "Service"
        case .experiences: return "Experiences"
        }
    }

    /// Optional SF Symbol for filter chips.
    var systemImage: String? {
        switch self {
        case .all: return "square.grid.2x2"
        case .cafe: return "cup.and.saucer"
        case .wellness: return "leaf"
        case .service: return "wrench.and.screwdriver"
        case .experiences: return "sparkles"
        }
    }
}
