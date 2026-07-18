//
//  Item.swift
//  SlotBook
//
//  Domain model for a listable experience on Home.
//  Iteration 2 focuses on presentation + navigation; booking comes later.
//

import Foundation

/// A bookable experience shown in the Items list.
///
/// Marked `nonisolated` so domain data stays free of UI actor isolation
/// under the project's default MainActor isolation mode.
nonisolated struct Item: Identifiable, Hashable, Sendable {
    let id: UUID
    /// Display title.
    let name: String
    /// Short marketing copy shown on cards and detail.
    let description: String
    /// SF Symbol name used as placeholder artwork (real images later).
    let imageName: String
    let category: ItemCategory
    /// Soft accent used for card artwork gradients.
    let color: ItemColor

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        imageName: String,
        category: ItemCategory,
        color: ItemColor
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.imageName = imageName
        self.category = category
        self.color = color
    }
}

/// Sendable RGB color (0…1 components) for item branding.
///
/// SwiftUI `Color` is not reliably `Sendable`; store components in the model
/// and convert at the view boundary via `ItemColor.swiftUIColor`.
nonisolated struct ItemColor: Hashable, Sendable {
    let red: Double
    let green: Double
    let blue: Double

    init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// Convenience from 0–255 sRGB integers.
    init(r: Int, g: Int, b: Int) {
        self.red = Double(r) / 255.0
        self.green = Double(g) / 255.0
        self.blue = Double(b) / 255.0
    }
}
