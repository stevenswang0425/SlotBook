//
//  Spacing.swift
//  SlotBook
//
//  Spacing, radius, and layout tokens for a calm, spacious UI.
//  Keep views free of magic numbers — reference these tokens instead.
//

import CoreGraphics

/// Layout spacing scale used across SlotBook.
///
/// Values follow a soft 4pt grid with generous defaults for a Calendly-like feel.
enum Spacing {
    /// 4 pt — hairline gaps
    static let xxs: CGFloat = 4
    /// 8 pt — tight related content
    static let xs: CGFloat = 8
    /// 12 pt — compact groups
    static let sm: CGFloat = 12
    /// 16 pt — standard padding
    static let md: CGFloat = 16
    /// 20 pt — comfortable section padding
    static let lg: CGFloat = 20
    /// 24 pt — screen horizontal margins
    static let xl: CGFloat = 24
    /// 32 pt — large section separation
    static let xxl: CGFloat = 32
    /// 48 pt — hero / empty-state breathing room
    static let xxxl: CGFloat = 48
}

/// Corner radius scale for continuous rounded rectangles.
enum Radius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let pill: CGFloat = 100
}

/// Shadow parameters for subtle elevation (cards, floating chrome).
enum Elevation {
    /// Soft card shadow — almost invisible, just enough lift.
    static let cardRadius: CGFloat = 16
    static let cardY: CGFloat = 4
    static let cardOpacity: Double = 0.06

    /// Slightly stronger for elevated sheets / FABs.
    static let raisedRadius: CGFloat = 24
    static let raisedY: CGFloat = 8
    static let raisedOpacity: Double = 0.10
}
