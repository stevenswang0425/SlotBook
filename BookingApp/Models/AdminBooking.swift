//
//  AdminBooking.swift
//  SlotBook
//
//  Owner-facing booking models (mock today → Supabase later).
//

import Foundation

/// Booking status for admin surfaces.
nonisolated enum AdminBookingStatus: String, Codable, Sendable, CaseIterable {
    case confirmed
    case cancelled
    case completed

    var displayName: String {
        switch self {
        case .confirmed: return "Confirmed"
        case .cancelled: return "Cancelled"
        case .completed: return "Completed"
        }
    }
}

/// A store-owned catalog service (mirrors Item for admin).
nonisolated struct AdminService: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let description: String
    let imageName: String
    let category: ItemCategory
    let color: ItemColor
    let durationMinutes: Int
}

/// One calendar cell: either free inventory or a booking.
nonisolated struct AdminSlotOccurrence: Identifiable, Hashable, Sendable {
    let id: UUID
    let serviceId: UUID
    let start: Date
    let end: Date
    /// `nil` means available.
    var booking: AdminBooking?

    var isBooked: Bool { booking != nil && booking?.status == .confirmed }
    var isAvailable: Bool { booking == nil }
}

/// Customer-facing fields shown to the owner.
nonisolated struct AdminBooking: Identifiable, Hashable, Sendable {
    let id: UUID
    let serviceId: UUID
    let serviceName: String
    let customerName: String
    let customerPhone: String
    let customerEmail: String?
    let start: Date
    let end: Date
    var status: AdminBookingStatus
    let referenceCode: String
    let isGuest: Bool
}
