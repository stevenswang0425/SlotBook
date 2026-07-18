//
//  RealtimeAvailabilitySimulator.swift
//  SlotBook
//
//  Simulates a multi-user backend by periodically reserving / releasing
//  time slots via Combine’s Timer publisher.
//
//  Design notes
//  ────────────
//  • Remote reservations live in `BookingStore.remoteReservedSlotIDs` so we
//    never cancel a real user booking by accident.
//  • Every mutation posts a `SlotAvailabilityNotice` the UI can toast on.
//  • Interval is intentionally calm (~9s) to match the product aesthetic.
//  • In production this would be replaced by WebSocket / push events.
//

import Combine
import Foundation

/// Drives live availability pulses against a shared `BookingStore`.
@MainActor
final class RealtimeAvailabilitySimulator {

    // MARK: - Configuration

    /// Seconds between remote activity pulses.
    var interval: TimeInterval = 9

    /// Probability that a pulse books a free slot (vs releasing a remote hold).
    var bookProbability: Double = 0.65

    // MARK: - State

    private let store: BookingStore
    private var cancellable: AnyCancellable?
    private(set) var isRunning: Bool = false

    // MARK: - Init

    init(store: BookingStore) {
        self.store = store
    }

    // MARK: - Lifecycle

    /// Starts the Combine timer. Safe to call multiple times (idempotent).
    func start() {
        guard !isRunning else { return }
        isRunning = true

        // `autoconnect` begins firing immediately after subscribe; we skip the
        // first tick so the user can orient before the first remote pulse.
        cancellable = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .dropFirst()
            .sink { [weak self] _ in
                self?.pulse()
            }
    }

    func stop() {
        cancellable?.cancel()
        cancellable = nil
        isRunning = false
    }

    // MARK: - Pulse

    /// One simulated remote action: either book a free slot or free a remote hold.
    func pulse() {
        let shouldBook: Bool
        if store.remoteReservedSlotIDs.isEmpty {
            shouldBook = true
        } else {
            shouldBook = Double.random(in: 0...1) < bookProbability
        }

        if shouldBook {
            simulateRemoteBooking()
        } else {
            simulateRemoteRelease()
        }
    }

    /// Force a single remote booking (useful for previews / tests).
    @discardableResult
    func simulateRemoteBooking() -> Bool {
        // Walk catalog items and pick a free half-hour window on a near day.
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for item in MockItems.catalog.shuffled() {
            for dayOffset in 0..<3 {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                    continue
                }
                let candidates = MockSlots.slots(for: day, itemID: item.id, calendar: calendar)
                    .filter { $0.isAvailable && !store.isSlotReserved($0.id) }

                guard let pick = candidates.randomElement() else { continue }
                store.reserveRemoteSlot(pick.id, itemID: item.id)
                return true
            }
        }
        return false
    }

    @discardableResult
    func simulateRemoteRelease() -> Bool {
        guard let slotID = store.remoteReservedSlotIDs.randomElement() else {
            return false
        }
        // Item id may be unknown for older holds — store tracks mapping.
        store.releaseRemoteSlot(slotID)
        return true
    }
}
