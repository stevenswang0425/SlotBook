//
//  CourtBookingDetailView.swift
//  SlotBook
//
//  Booking detail — club, schedule, guest, reference, cancel with policy.
//  Court numbers are never shown.
//

import SwiftUI

struct CourtBookingDetailView: View {
    let bookingID: UUID

    @Environment(\.bookingStore) private var bookingStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    /// Shared cancel orchestration from My Bookings list VM when available.
    var viewModel: BookingsViewModel?

    @State private var localPendingCancel = false
    @State private var isCancelling = false
    @State private var toastMessage: String?
    @State private var toastIsError = false

    private var booking: CourtBooking? {
        bookingStore.courtBooking(withID: bookingID)
    }

    private var club: BadmintonClub? {
        guard let booking else { return nil }
        return MockData.club(id: booking.clubId)
    }

    private var accent: Color {
        club?.primaryColor.swiftUIColor ?? themeManager.primary(for: colorScheme)
    }

    private var now: Date { viewModel?.now ?? Date() }

    var body: some View {
        // Observe store so cancel updates the detail live.
        let _ = bookingStore.reservationEpoch
        let _ = bookingStore.courtBookings

        Group {
            if let booking {
                detailContent(booking)
            } else {
                missingState
            }
        }
        .background(SBColor.background.ignoresSafeArea())
        .navigationTitle("Booking")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Cancel booking?",
            isPresented: $localPendingCancel
        ) {
            Button("Keep booking", role: .cancel) {
                localPendingCancel = false
            }
            Button("Cancel booking", role: .destructive) {
                Task { await performCancel() }
            }
        } message: {
            if let booking {
                Text(
                    "\(booking.clubName ?? "This booking") on \(booking.dateTimeLabel()) will be cancelled. "
                        + "Free cancellation up to 2 hours before start — the time opens for others."
                )
            }
        }
        .overlay(alignment: .bottom) {
            if let toastMessage {
                ToastBanner(
                    message: toastMessage,
                    style: toastIsError ? .warning : .success
                )
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xl)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: toastMessage)
        .onAppear {
            if let club {
                themeManager.applyClubTheme(club)
            }
        }
        .onDisappear {
            themeManager.clearClubTheme()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func detailContent(_ booking: CourtBooking) -> some View {
        let status = booking.displayStatus(now: now)
        let canCancel = booking.isUpcoming(now: now)

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                hero(booking)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(booking.clubName ?? "Court booking")
                            .font(.system(.title2, design: .default).weight(.bold))
                            .foregroundStyle(SBColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: Spacing.sm)

                        BookingStatusBadge(status: status)
                    }

                    if let club {
                        Label(club.locationLabel, systemImage: "mappin.and.ellipse")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(SBColor.textSecondary)
                    }
                }
                .padding(.horizontal, Spacing.xl)

                summaryCard(booking)

                guestCard(booking)

                policyCard

                if canCancel {
                    SecondaryButton(
                        title: isCancelling ? "Cancelling…" : "Cancel Booking",
                        isEnabled: !isCancelling
                    ) {
                        localPendingCancel = true
                        HapticFeedback.lightImpact()
                    }
                    .padding(.horizontal, Spacing.xl)
                    .opacity(isCancelling ? 0.7 : 1)
                } else if status == .cancelled {
                    CardView(showsShadow: false, showsBorder: true) {
                        Label("This booking was cancelled. The court time is available again.", systemImage: "info.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(SBColor.textSecondary)
                    }
                    .padding(.horizontal, Spacing.xl)
                }

                Spacer(minLength: Spacing.xxl)
            }
            .padding(.bottom, Spacing.xxl)
        }
    }

    private var missingState: some View {
        EmptyStateView(
            systemImage: "calendar.badge.exclamationmark",
            title: "Booking not found",
            message: "This reservation may have been removed.",
            actionTitle: "Go back",
            action: { dismiss() }
        )
    }

    // MARK: - Sections

    private func hero(_ booking: CourtBooking) -> some View {
        ZStack {
            LinearGradient(
                colors: [accent.opacity(0.95), accent.opacity(0.45), accent.opacity(0.28)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 140, height: 140)
                .offset(x: 80, y: -30)

            Image(systemName: club?.imageName ?? "figure.badminton")
                .font(.system(size: 56, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.95))
                .symbolRenderingMode(.hierarchical)
        }
        .frame(height: 160)
        .frame(maxWidth: .infinity)
        .clipShape(
            UnevenRoundedRectangle(
                bottomLeadingRadius: Radius.xl,
                bottomTrailingRadius: Radius.xl,
                style: .continuous
            )
        )
        .accessibilityHidden(true)
    }

    private func summaryCard(_ booking: CourtBooking) -> some View {
        CardView(showsShadow: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                detailRow(icon: "calendar", title: "Date", value: booking.dateLabel())
                Divider().opacity(0.45)
                detailRow(icon: "clock", title: "Time", value: booking.rangeLabel())
                Divider().opacity(0.45)
                detailRow(icon: "hourglass", title: "Duration", value: booking.durationLabel)
                Divider().opacity(0.45)
                detailRow(icon: "number", title: "Reference", value: booking.referenceCode)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .accessibilityElement(children: .combine)
    }

    private func guestCard(_ booking: CourtBooking) -> some View {
        CardView(showsShadow: false, showsBorder: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Guest")
                    .sbFontHeadline()
                detailRow(icon: "person", title: "Name", value: booking.name)
                Divider().opacity(0.45)
                detailRow(icon: "phone", title: "Phone", value: booking.phoneDisplay)
            }
        }
        .padding(.horizontal, Spacing.xl)
    }

    private var policyCard: some View {
        CardView(showsShadow: false, showsBorder: true) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(accent)
                    .font(.system(size: 16))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cancellation policy")
                        .font(.system(.subheadline, design: .default).weight(.semibold))
                        .foregroundStyle(SBColor.textPrimary)
                    Text(
                        "Free cancellation up to 2 hours before your start time. "
                            + "After that, please contact the club if you need to change plans."
                    )
                    .sbFontCaption()
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
        .accessibilityElement(children: .combine)
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 20)
            Text(title)
                .sbFontCaption()
            Spacer(minLength: Spacing.sm)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SBColor.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Cancel

    private func performCancel() async {
        guard let booking else { return }
        isCancelling = true
        localPendingCancel = false

        // Prefer shared VM so list toast + counts stay in sync.
        if let viewModel {
            viewModel.requestCancelCourt(booking)
            let ok = await viewModel.confirmCancel()
            isCancelling = false
            if ok {
                // Detail already reflects cancelled status via store observation.
                try? await Task.sleep(for: .milliseconds(350))
            }
            return
        }

        try? await Task.sleep(for: .milliseconds(420))
        if bookingStore.cancelCourtBooking(id: booking.id) != nil {
            toastIsError = false
            toastMessage = "Booking cancelled · court released"
            HapticFeedback.success()
            Task {
                try? await Task.sleep(for: .seconds(2.4))
                toastMessage = nil
            }
        } else {
            toastIsError = true
            toastMessage = "Couldn't cancel this booking. Please try again."
            HapticFeedback.error()
        }
        isCancelling = false
    }
}

// MARK: - Previews

#Preview("Detail — Upcoming") {
    let store = BookingStore()
    let start = Date().addingTimeInterval(86_400)
    let booking = CourtBooking.make(
        clubId: MockData.torontoClubId,
        clubName: "Toronto Badminton Club",
        courtId: UUID(),
        courtNumber: 2,
        slotId: UUID(),
        start: start,
        end: start.addingTimeInterval(3_600),
        durationMinutes: 60,
        guestName: "Alex Rivera",
        phoneDigits: "5551234567"
    )
    store.addCourtBooking(booking)

    return NavigationStack {
        CourtBookingDetailView(bookingID: booking.id)
    }
    .bookingStore(store)
    .themeManager(ThemeManager())
}

#Preview("Detail — Cancelled Dark") {
    let store = BookingStore()
    let start = Date().addingTimeInterval(172_800)
    var booking = CourtBooking.make(
        clubId: MockData.willowdaleClubId,
        clubName: "Willowdale Badminton Centre",
        courtId: UUID(),
        courtNumber: 1,
        slotId: UUID(),
        start: start,
        end: start.addingTimeInterval(2_700),
        durationMinutes: 45,
        guestName: "Sam Chen",
        phoneDigits: "5559876543"
    )
    store.addCourtBooking(booking)
    _ = store.cancelCourtBooking(id: booking.id)

    return NavigationStack {
        CourtBookingDetailView(bookingID: booking.id)
    }
    .bookingStore(store)
    .themeManager(ThemeManager())
    .preferredColorScheme(.dark)
}
