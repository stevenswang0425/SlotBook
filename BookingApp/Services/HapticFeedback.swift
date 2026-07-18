//
//  HapticFeedback.swift
//  SlotBook
//
//  Centralized haptic cues — keep feedback subtle and intentional.
//

import UIKit

/// Thin wrapper around UIKit feedback generators.
@MainActor
enum HapticFeedback {
    /// Successful booking / cancel confirmation.
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Validation or soft failure (slot taken, form errors).
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// Hard failure.
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    /// Light tap (chip select, favorite).
    static func lightImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Segment / discrete selection changes.
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
