//
//  CourtBookingViewModel.swift
//  SlotBook
//
//  Court booking flow: form → confirm → success, with auto court assignment.
//  (Marketplace experiences still use BookingViewModel.)
//

import Foundation
import Observation

@Observable
@MainActor
final class CourtBookingViewModel {

    // MARK: - Context

    let draft: CourtBookingDraft

    // MARK: - Form

    var guestName: String = ""
    var phoneDigits: String = ""
    var errors: BookingFormErrors = .none
    private(set) var hasAttemptedValidation: Bool = false

    // MARK: - Flow

    var step: BookingStep = .form
    var isSubmitting: Bool = false
    var submitError: String?
    private(set) var lastSubmitError: CourtBookingError?
    private(set) var completedBooking: CourtBooking?

    // MARK: - Dependencies

    private let clubRepository: any ClubRepository
    private weak var bookingStore: BookingStore?

    /// Demo hook: force next confirm to fail once (network).
    var forceNextSubmitFailure: Bool = false

    // MARK: - Derived

    var club: BadmintonClub { draft.club }
    var option: ClubStartOption { draft.option }
    var date: Date { draft.date }

    var phoneDisplay: String {
        PhoneNumberFormatter.applyMask(toDigits: phoneDigits)
    }

    var durationLabel: String {
        let minutes = draft.durationMinutes
        if minutes >= 60, minutes % 60 == 0 {
            let hours = minutes / 60
            return hours == 1 ? "1 hr" : "\(hours) hr"
        }
        return "\(minutes) min"
    }

    var isFormComplete: Bool {
        let trimmed = guestName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && PhoneNumberFormatter.isValid(digits: phoneDigits)
    }

    var estimatedPriceLabel: String { draft.estimatedPriceLabel }

    // MARK: - Init

    init(
        draft: CourtBookingDraft,
        clubRepository: any ClubRepository = MockClubRepository(),
        bookingStore: BookingStore? = nil,
        userSession: UserSession? = nil
    ) {
        self.draft = draft
        self.clubRepository = clubRepository
        self.bookingStore = bookingStore
        prefill(from: userSession)
    }

    func attach(store: BookingStore) {
        bookingStore = store
    }

    func prefill(from session: UserSession?) {
        guard let user = session?.currentUser, session?.isSignedIn == true else { return }
        if guestName.isEmpty {
            let name = user.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            if name.count >= 2, name.lowercased() != "guest" {
                guestName = name
            }
        }
        if phoneDigits.isEmpty, let phone = user.phone {
            phoneDigits = String(PhoneNumberFormatter.digits(from: phone).prefix(10))
        }
    }

    // MARK: - Form intentions

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
        submitError = nil
    }

    /// Confirms booking: re-assigns a free court internally, never exposes court #.
    func confirmBooking() async -> CourtBooking? {
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

        if forceNextSubmitFailure {
            forceNextSubmitFailure = false
            fail(.network)
            return nil
        }

        // Optimistic hold: mark the start option as taken in the store path via pending draft.
        // Real reserve happens after repository returns.

        let liveBusy = bookingStore?.courtBusyIntervals(
            clubId: club.id,
            on: date
        ) ?? []

        let request = CourtBookingCreateRequest(
            clubId: club.id,
            clubName: club.name,
            slotId: option.id,
            start: option.start,
            end: option.end,
            durationMinutes: option.durationMinutes,
            guestName: guestName.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneDigits: phoneDigits,
            email: nil,
            additionalBusy: liveBusy
        )

        do {
            // FUTURE: SupabaseClubRepository.createCourtBooking (atomic assign + insert)
            let booking = try await clubRepository.createCourtBooking(request)

            // Late race at store boundary (another local confirm finished first).
            if let store = bookingStore {
                let stillBusy = store.courtBusyIntervals(clubId: club.id, on: date)
                let conflict = stillBusy.contains {
                    $0.courtId == booking.courtId && $0.overlaps(booking.start, booking.end)
                }
                if conflict {
                    fail(.slotUnavailable)
                    return nil
                }
            }

            completedBooking = booking
            isSubmitting = false
            step = .success
            HapticFeedback.success()
            return booking
        } catch let error as CourtBookingError {
            fail(error)
            return nil
        } catch {
            fail(.unknown)
            return nil
        }
    }

    // MARK: - Private

    private func fail(_ error: CourtBookingError) {
        lastSubmitError = error
        submitError = error.errorDescription
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
