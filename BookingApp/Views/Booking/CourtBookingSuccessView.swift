//
//  CourtBookingSuccessView.swift
//  SlotBook
//
//  Calm success screen after a court booking — no court numbers.
//

import SwiftUI

struct CourtBookingSuccessView: View {
    let booking: CourtBooking
    var onViewBookings: () -> Void
    var onBookAnother: () -> Void
    var onAddToCalendar: (() -> Void)? = nil

    @State private var checkScale: CGFloat = 0.4
    @State private var checkOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.6
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 16
    @State private var calendarToast = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: Spacing.xl)

            celebration

            VStack(spacing: Spacing.sm) {
                Text("You're all set")
                    .sbFontTitle()
                    .multilineTextAlignment(.center)

                Text("Your court is reserved. We’ll have it ready when you arrive.")
                    .sbFontBody()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
            .opacity(contentOpacity)
            .offset(y: contentOffset)
            .padding(.top, Spacing.xl)

            detailsCard
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.xl)
                .opacity(contentOpacity)
                .offset(y: contentOffset)

            Button {
                onAddToCalendar?()
                calendarToast = true
                HapticFeedback.lightImpact()
            } label: {
                Label("Add to Calendar", systemImage: "calendar.badge.plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SBColor.primary)
            }
            .padding(.top, Spacing.md)
            .opacity(contentOpacity)
            .accessibilityHint("Placeholder — calendar export comes later")

            if calendarToast {
                Text("Calendar export is coming soon")
                    .sbFontCaption()
                    .padding(.top, Spacing.xs)
                    .transition(.opacity)
            }

            Spacer()

            VStack(spacing: Spacing.sm) {
                PrimaryButton(title: "View My Bookings", action: onViewBookings)
                SecondaryButton(title: "Book Another", action: onBookAnother)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.lg)
            .opacity(contentOpacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SBColor.background.ignoresSafeArea())
        .onAppear(perform: runEntrance)
        .animation(.easeOut(duration: 0.25), value: calendarToast)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Celebration

    private var celebration: some View {
        ZStack {
            Circle()
                .stroke(SBColor.success.opacity(0.25), lineWidth: 3)
                .frame(width: 120, height: 120)
                .scaleEffect(ringScale)
                .opacity(checkOpacity)

            Circle()
                .fill(SBColor.success.opacity(0.12))
                .frame(width: 104, height: 104)
                .scaleEffect(checkScale)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(SBColor.success)
                .symbolRenderingMode(.hierarchical)
                .scaleEffect(checkScale)
                .opacity(checkOpacity)
        }
        .accessibilityLabel("Booking confirmed")
    }

    private var detailsCard: some View {
        CardView(showsShadow: false, showsBorder: true) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                row(title: "Club", value: booking.clubName ?? "Badminton club")
                Divider().overlay(SBColor.border)
                row(title: "When", value: "\(booking.dateLabel()) · \(booking.rangeLabel())")
                Divider().overlay(SBColor.border)
                row(title: "Duration", value: booking.durationLabel)
                Divider().overlay(SBColor.border)
                row(title: "Guest", value: booking.name)
                Divider().overlay(SBColor.border)
                row(title: "Reference", value: booking.referenceCode)
            }
        }
    }

    private func row(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .sbFontCaption()
            Spacer(minLength: Spacing.sm)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SBColor.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func runEntrance() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
            checkScale = 1
            checkOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.7)) {
            ringScale = 1.25
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.18)) {
            contentOpacity = 1
            contentOffset = 0
        }
    }
}

// MARK: - Previews

#Preview("Court success — Light") {
    let booking = CourtBooking.make(
        clubId: MockData.torontoClubId,
        clubName: "Toronto Badminton Club",
        courtId: UUID(),
        courtNumber: 3,
        slotId: UUID(),
        start: Date().addingTimeInterval(86_400),
        end: Date().addingTimeInterval(86_400 + 3_600),
        durationMinutes: 60,
        guestName: "Alex Rivera",
        phoneDigits: "5551234567"
    )
    CourtBookingSuccessView(booking: booking, onViewBookings: {}, onBookAnother: {})
        .themeManager(ThemeManager())
}

#Preview("Court success — Dark") {
    let booking = CourtBooking.make(
        clubId: MockData.willowdaleClubId,
        clubName: "Willowdale Badminton Centre",
        courtId: UUID(),
        courtNumber: 1,
        slotId: UUID(),
        start: Date().addingTimeInterval(172_800),
        end: Date().addingTimeInterval(172_800 + 2_700),
        durationMinutes: 45,
        guestName: "Sam Chen",
        phoneDigits: "5559876543"
    )
    CourtBookingSuccessView(booking: booking, onViewBookings: {}, onBookAnother: {})
        .themeManager(ThemeManager())
        .preferredColorScheme(.dark)
}
