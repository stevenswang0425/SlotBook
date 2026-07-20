//
//  ClubDetailViewModel.swift
//  SlotBook
//
//  Club detail: date + duration + hidden-court availability + booking flow.
//

import Foundation
import Observation

@Observable
@MainActor
final class ClubDetailViewModel {
    // MARK: - Club

    let club: BadmintonClub

    private(set) var courts: [Court] = []
    private(set) var hasLoadedCourts: Bool = false
    private(set) var isLoadingCourts: Bool = false

    // MARK: - Schedule selection

    private(set) var days: [SelectableDay] = []
    var selectedDate: Date
    var selectedDuration: CourtBookingDuration = .sixty

    private(set) var startOptions: [ClubStartOption] = []
    var selectedOptionID: UUID?
    var isLoadingSlots: Bool = false
    var loadError: String?

    // MARK: - Booking sheet (full Iteration 4 flow)

    var isBookingSheetPresented: Bool = false
    private(set) var bookingDraft: CourtBookingDraft?

    /// Soft feedback after success / guidance.
    var toastMessage: String?
    var showToast: Bool = false

    // MARK: - Dependencies

    private let clubRepository: any ClubRepository
    private weak var bookingStore: BookingStore?
    private let calendar: Calendar

    private var slotsTask: Task<Void, Never>?

    // MARK: - Init

    init(
        club: BadmintonClub,
        clubRepository: any ClubRepository = MockClubRepository(),
        calendar: Calendar = .current,
        now: Date = Date()
    ) {
        self.club = club
        self.clubRepository = clubRepository
        self.calendar = calendar
        let today = calendar.startOfDay(for: now)
        self.selectedDate = today
        self.days = MockSlots.upcomingDays(count: 14, from: now, calendar: calendar)
    }

    // MARK: - Derived

    var activeCourtCount: Int {
        let active = courts.filter(\.isActive).count
        return active > 0 ? active : club.totalCourts
    }

    var courtsStatLabel: String {
        activeCourtCount == 1 ? "1 court" : "\(activeCourtCount) courts"
    }

    var openingHoursLabel: String { club.openingHours }

    var selectedOption: ClubStartOption? {
        guard let selectedOptionID else { return nil }
        return startOptions.first { $0.id == selectedOptionID && $0.isAvailable }
    }

    var availableCount: Int {
        startOptions.filter(\.isAvailable).count
    }

    var availabilitySummary: String {
        if isLoadingSlots { return "Checking courts…" }
        if let loadError { return loadError }
        if startOptions.isEmpty { return "No times for this day." }
        if availableCount == 0 {
            return "Fully booked for \(selectedDuration.label) — try another duration or day."
        }
        return availableCount == 1
            ? "1 opening · \(selectedDuration.label)"
            : "\(availableCount) openings · \(selectedDuration.label)"
    }

    var canContinueBooking: Bool { selectedOption != nil }

    var bookButtonTitle: String {
        if let option = selectedOption {
            return "Book \(option.startLabel())"
        }
        return "Select a time"
    }

    // MARK: - Lifecycle

    func attach(store: BookingStore) {
        bookingStore = store
    }

    func load() async {
        if !hasLoadedCourts {
            await fetchCourts()
        }
        await reloadSlots()
    }

    func onDisappear() {
        slotsTask?.cancel()
        slotsTask = nil
    }

    /// Re-run availability when local court bookings change.
    func handleStoreReservationChange() {
        scheduleSlotReload()
    }

    // MARK: - Selection

    func selectDate(_ date: Date) {
        let day = calendar.startOfDay(for: date)
        guard !calendar.isDate(day, inSameDayAs: selectedDate) else { return }
        selectedDate = day
        selectedOptionID = nil
        HapticFeedback.selection()
        scheduleSlotReload()
    }

    func selectDuration(_ duration: CourtBookingDuration) {
        guard selectedDuration != duration else { return }
        selectedDuration = duration
        selectedOptionID = nil
        HapticFeedback.selection()
        scheduleSlotReload()
    }

    func selectOption(_ option: ClubStartOption) {
        guard option.isAvailable else { return }
        selectedOptionID = option.id
        HapticFeedback.selection()
        presentBookingSheet(for: option)
    }

    func bookCourtTapped() {
        HapticFeedback.lightImpact()
        if let option = selectedOption {
            presentBookingSheet(for: option)
        } else {
            presentToast("Pick an available time below.")
        }
    }

    func dismissBookingSheet() {
        isBookingSheetPresented = false
    }

    /// After a successful confirm — refresh grid and celebrate calmly.
    func handleBookingCompleted(_ booking: CourtBooking) {
        bookingStore?.setPendingCourtDraft(nil)
        selectedOptionID = nil
        isBookingSheetPresented = false
        scheduleSlotReload()
        presentToast("Booked · \(booking.referenceCode)")
    }

    func dismissToast() {
        showToast = false
        toastMessage = nil
    }

    // MARK: - Data

    private func fetchCourts() async {
        isLoadingCourts = true
        loadError = nil
        do {
            courts = try await clubRepository.fetchCourts(clubId: club.id)
            hasLoadedCourts = true
        } catch {
            loadError = error.localizedDescription
        }
        isLoadingCourts = false
    }

    private func scheduleSlotReload() {
        slotsTask?.cancel()
        slotsTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(80))
            guard let self, !Task.isCancelled else { return }
            await self.reloadSlots()
        }
    }

    private func reloadSlots() async {
        isLoadingSlots = true
        loadError = nil

        let liveBusy = bookingStore?.courtBusyIntervals(
            clubId: club.id,
            on: selectedDate,
            calendar: calendar
        ) ?? []

        do {
            let options = try await clubRepository.findAvailableSlots(
                clubId: club.id,
                date: selectedDate,
                durationMinutes: selectedDuration.minutes,
                additionalBusy: liveBusy
            )
            guard !Task.isCancelled else { return }
            startOptions = options
            if let selectedOptionID,
               !options.contains(where: { $0.id == selectedOptionID && $0.isAvailable }) {
                self.selectedOptionID = nil
            }
        } catch {
            if !Task.isCancelled {
                loadError = error.localizedDescription
                startOptions = []
            }
        }

        isLoadingSlots = false
    }

    private func presentBookingSheet(for option: ClubStartOption) {
        let draft = CourtBookingDraft(
            club: club,
            option: option,
            date: selectedDate
        )
        bookingDraft = draft
        bookingStore?.setPendingCourtDraft(draft)
        isBookingSheetPresented = true
    }

    private func presentToast(_ message: String) {
        toastMessage = message
        showToast = true
    }
}
