//
//  BookingViewModel.swift
//  SlotBook
//
//  Multi-step booking flow: form → confirm → success, with error handling.
//

import Foundation
import Observation

enum BookingStep: Equatable, Sendable {
    case form
    case confirm
    case success
}

struct BookingFormErrors: Equatable, Sendable {
    var name: String?
    var phone: String?

    var hasErrors: Bool { name != nil || phone != nil }

    static let none = BookingFormErrors(name: nil, phone: nil)
}

/// Errors that can surface during confirm (network / race conditions).
enum BookingSubmitError: Equatable, Sendable {
    case slotUnavailable
    case network
    case unknown

    var userMessage: String {
        switch self {
        case .slotUnavailable:
            return "This slot was just taken. Please go back and pick another time."
        case .network:
            return "We couldn't reach the server. Check your connection and try again."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}

@Observable
@MainActor
final class BookingViewModel {

    // MARK: - Context

    let item: Item
    let slot: TimeSlot
    let date: Date

    // MARK: - Form

    var guestName: String = ""
    var phoneDigits: String = ""
    var errors: BookingFormErrors = .none
    private(set) var hasAttemptedValidation: Bool = false

    // MARK: - Flow

    var step: BookingStep = .form
    var isSubmitting: Bool = false
    var submitError: String?
    private(set) var lastSubmitError: BookingSubmitError?
    private(set) var completedBooking: Booking?

    /// Optional shared store for race detection (slot taken mid-flow).
    private weak var bookingStore: BookingStore?

    /// Demo hook: when `true`, the next confirm fails with a network error once.
    var forceNextSubmitFailure: Bool = false

    // MARK: - Derived

    var phoneDisplay: String {
        PhoneNumberFormatter.applyMask(toDigits: phoneDigits)
    }

    var durationLabel: String {
        let minutes = slot.durationMinutes
        return minutes == 1 ? "1 min" : "\(minutes) min"
    }

    var isFormComplete: Bool {
        let trimmed = guestName.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameOK = trimmed.count >= 2
        let phoneOK = PhoneNumberFormatter.isValid(digits: phoneDigits)
        return nameOK && phoneOK
    }

    // MARK: - Init

    init(item: Item, slot: TimeSlot, date: Date, bookingStore: BookingStore? = nil) {
        self.item = item
        self.slot = slot
        self.date = date
        self.bookingStore = bookingStore
    }

    func attach(store: BookingStore) {
        bookingStore = store
    }

    // MARK: - Intentions

    func updatePhone(fromFormatted text: String) {
        phoneDigits = String(PhoneNumberFormatter.digits(from: text).prefix(10))
        if hasAttemptedValidation { revalidateFieldErrors() }
    }

    func updateName(_ text: String) {
        guestName = text
        if hasAttemptedValidation { revalidateFieldErrors() }
    }

    @discardableResult
    func continueToConfirm() -> Bool {
        hasAttemptedValidation = true
        revalidateFieldErrors()
        guard !errors.hasErrors else {
            HapticFeedback.warning()
            return false
        }
        submitError = nil
        lastSubmitError = nil
        step = .confirm
        HapticFeedback.selection()
        return true
    }

    func backToForm() {
        guard !isSubmitting else { return }
        step = .form
    }

    /// Simulates network booking with race + transient error handling.
    func confirmBooking() async -> Booking? {
        guard isFormComplete else {
            hasAttemptedValidation = true
            revalidateFieldErrors()
            step = .form
            HapticFeedback.warning()
            return nil
        }

        isSubmitting = true
        submitError = nil
        lastSubmitError = nil

        // Simulated API latency.
        try? await Task.sleep(for: .milliseconds(1100))

        // Forced failure path (tests / demos).
        if forceNextSubmitFailure {
            forceNextSubmitFailure = false
            fail(.network)
            return nil
        }

        // Race: another guest (or the simulator) took the slot while we were confirming.
        if bookingStore?.isSlotReserved(slot.id) == true {
            fail(.slotUnavailable)
            return nil
        }

        let booking = Booking.make(
            item: item,
            slot: slot,
            date: date,
            guestName: guestName.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneDigits: phoneDigits
        )

        completedBooking = booking
        isSubmitting = false
        step = .success
        HapticFeedback.success()
        return booking
    }

    /// Surfaces a late race detected after `confirmBooking` returned.
    func markLateSlotConflict() {
        completedBooking = nil
        step = .confirm
        fail(.slotUnavailable)
    }

    // MARK: - Private

    private func fail(_ error: BookingSubmitError) {
        lastSubmitError = error
        submitError = error.userMessage
        isSubmitting = false
        HapticFeedback.error()
    }

    private func revalidateFieldErrors() {
        errors = validate()
    }

    private func validate() -> BookingFormErrors {
        var result = BookingFormErrors.none
        let trimmed = guestName.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            result.name = "Name is required"
        } else if trimmed.count < 2 {
            result.name = "Enter at least 2 characters"
        }

        if phoneDigits.isEmpty {
            result.phone = "Phone number is required"
        } else if !PhoneNumberFormatter.isValid(digits: phoneDigits) {
            result.phone = "Enter a valid 10-digit phone number"
        }

        return result
    }
}
