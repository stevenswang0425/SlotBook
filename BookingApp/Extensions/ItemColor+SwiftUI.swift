//
//  ItemColor+SwiftUI.swift
//  SlotBook
//
//  Bridges domain color components to SwiftUI.
//

import SwiftUI

extension ItemColor {
    /// SwiftUI color for gradients, badges, and accents.
    var swiftUIColor: Color {
        Color(red: red, green: green, blue: blue)
    }

    /// Lighter wash of the accent (card gradient end / badge fill).
    var softWash: Color {
        swiftUIColor.opacity(0.18)
    }
}
