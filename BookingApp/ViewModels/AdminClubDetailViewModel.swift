//
//  AdminClubDetailViewModel.swift
//  SlotBook
//
//  Club admin: edit info, manage courts (numbers visible), view bookings.
//

import Foundation
import Observation

@Observable
@MainActor
final class AdminClubDetailViewModel {

    // MARK: - Identity

    let clubId: UUID

    // MARK: - Editable club

    var name: String = ""
    var descriptionText: String = ""
    var address: String = ""
    var city: String = ""
    var openingHours: String = ""
    var pricePerHourCAD: Int = 0
    var imageName: String = "figure.badminton"
    var primaryColor: ItemColor = ItemColor(r: 37, g: 99, b: 235)
    var tagline: String = ""
    var amenities: [String] = []
    var isIndoor: Bool = true
    var hasCoaching: Bool = false

    // MARK: - Courts & bookings

    private(set) var courts: [AdminManagedCourt] = []
    private(set) var isLoading = false
    private(set) var isSaving = false
    var errorMessage: String?
    var toastMessage: String?
    var showToast = false

    private(set) var now: Date = Date()

    // MARK: - Dependencies

    private let adminRepository: any AdminClubRepository
    private weak var bookingStore: BookingStore?
    private let calendar: Calendar

    init(
        clubId: UUID,
        adminRepository: any AdminClubRepository = MockAdminClubRepository.shared,
        calendar: Calendar = .current
    ) {
        self.clubId = clubId
        self.adminRepository = adminRepository
        self.calendar = calendar
    }

    func attach(store: BookingStore) {
        bookingStore = store
    }

    // MARK: - Derived

    var activeCourtCount: Int { courts.filter(\.isActive).count }

    var clubName: String { name }

    var todayBookings: [AdminCourtBookingRow] {
        bookings(on: now)
    }

    var weekBookings: [AdminCourtBookingRow] {
        guard let store = bookingStore else { return [] }
        let weekStart = Self.startOfWeek(for: now, calendar: calendar)
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
        return store.courtBookings
            .filter {
                $0.clubId == clubId
                    && $0.start >= weekStart
                    && $0.start < weekEnd
            }
            .map { AdminCourtBookingRow.from($0) }
            .sorted { $0.start < $1.start }
    }

    func bookings(on day: Date) -> [AdminCourtBookingRow] {
        guard let store = bookingStore else { return [] }
        let dayStart = calendar.startOfDay(for: day)
        return store.courtBookings
            .filter {
                $0.clubId == clubId && calendar.isDate($0.start, inSameDayAs: dayStart)
            }
            .map { AdminCourtBookingRow.from($0) }
            .sorted { $0.start < $1.start }
    }

    func bookings(forCourt courtId: UUID) -> [AdminCourtBookingRow] {
        guard let store = bookingStore else { return [] }
        return store.courtBookings
            .filter { $0.clubId == clubId && $0.courtId == courtId && $0.status == .confirmed && $0.end > now }
            .map { AdminCourtBookingRow.from($0) }
            .sorted { $0.start < $1.start }
    }

    // MARK: - Load / save

    func load() async {
        isLoading = true
        errorMessage = nil
        now = Date()
        do {
            let clubs = try await adminRepository.fetchManagedClubs()
            guard let club = clubs.first(where: { $0.id == clubId }) else {
                errorMessage = "Club not found."
                isLoading = false
                return
            }
            applyClub(club)
            courts = try await adminRepository.fetchManagedCourts(clubId: clubId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func saveClub() async {
        isSaving = true
        errorMessage = nil
        let draft = AdminManagedClub(
            id: clubId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
            imageName: imageName,
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
            primaryColor: primaryColor,
            tagline: tagline,
            amenities: amenities,
            pricePerHourCAD: pricePerHourCAD,
            isIndoor: isIndoor,
            hasCoaching: hasCoaching,
            openingHours: openingHours.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        do {
            let saved = try await adminRepository.updateClub(draft)
            applyClub(saved)
            presentToast("Club details saved")
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticFeedback.error()
        }
        isSaving = false
    }

    // MARK: - Courts

    func toggleCourtActive(_ court: AdminManagedCourt) async {
        do {
            let updated = try await adminRepository.setCourtActive(
                courtId: court.id,
                isActive: !court.isActive
            )
            if let index = courts.firstIndex(where: { $0.id == updated.id }) {
                courts[index] = updated
            }
            HapticFeedback.selection()
            presentToast(updated.isActive ? "Court \(updated.courtNumber) active" : "Court \(updated.courtNumber) inactive")
        } catch {
            errorMessage = error.localizedDescription
            HapticFeedback.error()
        }
    }

    func addCourt() async {
        do {
            let court = try await adminRepository.addCourt(clubId: clubId)
            courts.append(court)
            courts.sort { $0.courtNumber < $1.courtNumber }
            HapticFeedback.success()
            presentToast("Added Court \(court.courtNumber)")
        } catch {
            errorMessage = error.localizedDescription
            HapticFeedback.error()
        }
    }

    func removeCourt(_ court: AdminManagedCourt) async {
        // Block remove if upcoming confirmed bookings on this court.
        let upcoming = bookings(forCourt: court.id)
        if !upcoming.isEmpty {
            errorMessage = "Court \(court.courtNumber) has upcoming bookings. Cancel them first."
            HapticFeedback.warning()
            return
        }
        do {
            try await adminRepository.removeCourt(courtId: court.id)
            courts.removeAll { $0.id == court.id }
            HapticFeedback.success()
            presentToast("Removed Court \(court.courtNumber)")
        } catch {
            errorMessage = error.localizedDescription
            HapticFeedback.error()
        }
    }

    @discardableResult
    func cancelBooking(id: UUID) -> Bool {
        guard let store = bookingStore else { return false }
        if store.cancelCourtBooking(id: id) != nil {
            now = Date()
            presentToast("Booking cancelled")
            HapticFeedback.success()
            return true
        }
        HapticFeedback.error()
        return false
    }

    func dismissToast() {
        showToast = false
        toastMessage = nil
    }

    // MARK: - Private

    private func applyClub(_ club: AdminManagedClub) {
        name = club.name
        descriptionText = club.description
        address = club.address
        city = club.city
        openingHours = club.openingHours
        pricePerHourCAD = club.pricePerHourCAD
        imageName = club.imageName
        primaryColor = club.primaryColor
        tagline = club.tagline
        amenities = club.amenities
        isIndoor = club.isIndoor
        hasCoaching = club.hasCoaching
    }

    private func presentToast(_ message: String) {
        toastMessage = message
        showToast = true
    }

    nonisolated private static func startOfWeek(for date: Date, calendar: Calendar) -> Date {
        var cal = calendar
        cal.firstWeekday = 2
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: components).map { cal.startOfDay(for: $0) }
            ?? cal.startOfDay(for: date)
    }
}
