//
//  MockItems.swift
//  SlotBook
//
//  Deterministic mock catalog for the Items list.
//  Replace with an API-backed repository in a later iteration.
//

import Foundation

enum MockItems {
    /// Curated sample items spanning every filterable category.
    nonisolated static let catalog: [Item] = [
        Item(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222201")!,
            name: "Pour-Over Flight",
            description: "Three single-origin pour-overs with guided tasting notes and a quiet corner seat.",
            imageName: "cup.and.saucer.fill",
            category: .cafe,
            color: ItemColor(r: 180, g: 120, b: 72)
        ),
        Item(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222202")!,
            name: "Morning Flow Yoga",
            description: "A gentle 60-minute vinyasa to open the day — breath, balance, and soft light.",
            imageName: "figure.yoga",
            category: .wellness,
            color: ItemColor(r: 72, g: 160, b: 132)
        ),
        Item(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222203")!,
            name: "Device Tune-Up",
            description: "Diagnostics, clean, and software refresh for phones and laptops. Same-day slots.",
            imageName: "laptopcomputer.and.iphone",
            category: .service,
            color: ItemColor(r: 70, g: 110, b: 200)
        ),
        Item(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222204")!,
            name: "Pottery Basics",
            description: "Wheel-throwing intro for beginners. Leave with your first piece and a calm mind.",
            imageName: "hands.sparkles",
            category: .experiences,
            color: ItemColor(r: 150, g: 100, b: 180)
        ),
        Item(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222205")!,
            name: "Sauna & Steam Ritual",
            description: "Private suite with guided heat cycles and a cold plunge finish. Unwind fully.",
            imageName: "humidity.fill",
            category: .wellness,
            color: ItemColor(r: 60, g: 140, b: 170)
        ),
    ]
}
