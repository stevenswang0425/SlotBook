//
//  View+CardShadow.swift
//  SlotBook
//
//  Subtle elevation helpers for the minimalist card aesthetic.
//

import SwiftUI

extension View {
    /// Soft, almost invisible shadow used on cards and elevated surfaces.
    func sbCardShadow() -> some View {
        self.shadow(
            color: Color.black.opacity(Elevation.cardOpacity),
            radius: Elevation.cardRadius,
            x: 0,
            y: Elevation.cardY
        )
    }

    /// Slightly stronger elevation for floating elements.
    func sbRaisedShadow() -> some View {
        self.shadow(
            color: Color.black.opacity(Elevation.raisedOpacity),
            radius: Elevation.raisedRadius,
            x: 0,
            y: Elevation.raisedY
        )
    }
}
