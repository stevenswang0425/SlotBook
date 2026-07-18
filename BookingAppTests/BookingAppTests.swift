//
//  BookingAppTests.swift
//  BookingAppTests
//
//  Unit tests for SlotBook (Iterations 1–6).
//

import Foundation
import Testing
@testable import BookingApp

struct BookingAppTests {

    @Test func mockCatalogHasExpectedCount() {
        #expect(MockItems.catalog.count == 5)
    }

    @Test func phoneFormatterAppliesMask() {
        #expect(PhoneNumberFormatter.applyMask(toDigits: "5551234567") == "(555) 123-4567")
    }

    // MARK: - Booking form

    @Test @MainActor
    func bookingFormRejectsEmptyFields() {
        let ctx = sampleContext()
        let vm = BookingViewModel(item: ctx.item, slot: ctx.slot, date: ctx.date)
        #expect(!vm.continueToConfirm())
        #expect(vm.step == .form)
    }

    @Test @MainActor
    func confirmBookingProducesReference() async {
        let store = BookingStore()
        let ctx = sampleContext()
        let vm = BookingViewModel(item: ctx.item, slot: ctx.slot, date: ctx.date, bookingStore: store)
        vm.updateName("Sam Chen")
        vm.updatePhone(fromFormatted: "5559876543")
        #expect(vm.continueToConfirm())

        let booking = await vm.confirmBooking()
        #expect(booking?.referenceCode.hasPrefix("SB-") == true)
        #expect(vm.step == .success)
    }

    @Test @MainActor
    func confirmFailsWhenSlotAlreadyReserved() async {
        let store = BookingStore()
        let ctx = sampleContext()
        store.reserveRemoteSlot(ctx.slot.id, itemID: ctx.item.id)

        let vm = BookingViewModel(item: ctx.item, slot: ctx.slot, date: ctx.date, bookingStore: store)
        vm.updateName("Sam Chen")
        vm.updatePhone(fromFormatted: "5559876543")
        _ = vm.continueToConfirm()

        let booking = await vm.confirmBooking()
        #expect(booking == nil)
        #expect(vm.lastSubmitError == .slotUnavailable)
        #expect(vm.step == .confirm)
    }

    @Test @MainActor
    func confirmFailsOnForcedNetworkError() async {
        let ctx = sampleContext()
        let vm = BookingViewModel(item: ctx.item, slot: ctx.slot, date: ctx.date)
        vm.updateName("Sam Chen")
        vm.updatePhone(fromFormatted: "5559876543")
        _ = vm.continueToConfirm()
        vm.forceNextSubmitFailure = true

        let booking = await vm.confirmBooking()
        #expect(booking == nil)
        #expect(vm.lastSubmitError == .network)
    }

    // MARK: - Realtime store

    @Test @MainActor
    func remoteReservePublishesNotice() {
        let store = BookingStore()
        let item = MockItems.catalog[0]
        let slotID = UUID()
        store.reserveRemoteSlot(slotID, itemID: item.id)

        #expect(store.isSlotReserved(slotID))
        #expect(store.remoteReservedSlotIDs.contains(slotID))
        #expect(store.lastNotice?.source == .remoteBooking)
        #expect(store.lastNotice?.message == "Someone just booked this slot")
    }

    @Test @MainActor
    func remoteReleaseFreesSlot() {
        let store = BookingStore()
        let item = MockItems.catalog[0]
        let slotID = UUID()
        store.reserveRemoteSlot(slotID, itemID: item.id)
        store.releaseRemoteSlot(slotID)

        #expect(!store.isSlotReserved(slotID))
        #expect(store.lastNotice?.source == .remoteRelease)
    }

    @Test @MainActor
    func cancelReleasesReservedSlot() {
        let store = BookingStore()
        let ctx = sampleContext()
        let booking = Booking.make(
            item: ctx.item,
            slot: ctx.slot,
            date: ctx.date,
            guestName: "Alex",
            phoneDigits: "5551234567"
        )
        store.add(booking)
        #expect(store.isSlotReserved(booking.slot.id))

        let cancelled = store.cancel(id: booking.id)
        #expect(cancelled?.status == .cancelled)
        #expect(!store.isSlotReserved(booking.slot.id))
        #expect(store.lastNotice?.source == .localCancel)
    }

    @Test @MainActor
    func bookingsViewModelCancelFlow() async {
        let store = BookingStore()
        let ctx = sampleContext()
        let booking = Booking.make(
            item: ctx.item,
            slot: ctx.slot,
            date: ctx.date,
            guestName: "Alex",
            phoneDigits: "5551234567"
        )
        store.add(booking)

        let vm = BookingsViewModel(store: store)
        vm.requestCancel(booking)
        await vm.confirmCancel()
        #expect(vm.displayedBookings.isEmpty)
        #expect(vm.toastMessage != nil)
        #expect(!vm.toastIsError)
    }

    @Test @MainActor
    func detailReflectsRemoteReservation() {
        let store = BookingStore()
        let item = MockItems.catalog[0]
        let vm = ItemDetailViewModel(item: item)
        vm.attach(store: store)

        guard let available = vm.slots.first(where: \.isAvailable) else {
            Issue.record("Expected available slot")
            return
        }

        store.reserveRemoteSlot(available.id, itemID: item.id)
        vm.handleStoreReservationChange()
        #expect(vm.slots.first { $0.id == available.id }?.isBooked == true)
    }

    @Test @MainActor
    func simulatorCanBookRemotely() {
        let store = BookingStore()
        let simulator = RealtimeAvailabilitySimulator(store: store)
        let booked = simulator.simulateRemoteBooking()
        #expect(booked)
        #expect(!store.remoteReservedSlotIDs.isEmpty)
    }

    // MARK: - Helpers

    @MainActor
    private func sampleContext() -> (item: Item, slot: TimeSlot, date: Date) {
        let item = MockItems.catalog[0]
        let date = Calendar.current.startOfDay(for: Date())
        let start = Date().addingTimeInterval(3600)
        let end = start.addingTimeInterval(30 * 60)
        let base = MockSlots.slots(for: date, itemID: item.id).first(where: \.isAvailable)
        let slot = TimeSlot(
            id: base?.id ?? UUID(),
            start: start,
            end: end,
            availability: .available
        )
        return (item, slot, date)
    }
}
