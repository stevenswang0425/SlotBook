//
//  SlotAvailabilityNotice.swift
//  SlotBook
//
//  Lightweight event model for live availability changes.
//  Used by Item Detail toasts and cross-screen sync.
//

import Foundation

/// Why a slot’s availability changed.
nonisolated enum SlotChangeSource: String, Sendable, Hashable {
    /// The local user completed a booking.
    case localBooking
    /// The local user cancelled a booking.
    case localCancel
    /// Simulated remote activity (another “guest” booked).
    case remoteBooking
    /// Simulated remote activity (another “guest” released).
    case remoteRelease
}

/// Broadcast when a slot becomes taken or freed.
nonisolated struct SlotAvailabilityNotice: Identifiable, Equatable, Sendable {
    enum Kind: String, Sendable {
        case taken
        case freed
    }

    let id: UUID
    let kind: Kind
    let slotID: UUID
    let itemID: UUID
    let source: SlotChangeSource
    let message: String
    let createdAt: Date

    init(
        kind: Kind,
        slotID: UUID,
        itemID: UUID,
        source: SlotChangeSource,
        message: String,
        id: UUID = UUID(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.slotID = slotID
        self.itemID = itemID
        self.source = source
        self.message = message
        self.createdAt = createdAt
    }
}
