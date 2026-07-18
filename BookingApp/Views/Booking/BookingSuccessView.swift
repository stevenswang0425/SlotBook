//
//  BookingSuccessView.swift
//  SlotBook
//
//  Full-screen celebration after a successful booking.
//

import SwiftUI

struct BookingSuccessView: View {
    let booking: Booking
    var onViewBookings: () -> Void
    var onBookAnother: () -> Void

    @State private var checkScale: CGFloat = 0.4
    @State private var checkOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.6
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 16

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: Spacing.xl)

            celebration

            VStack(spacing: Spacing.sm) {
                Text("You're all set")
                    .sbFontTitle()
                    .multilineTextAlignment(.center)

                Text("Your booking is confirmed. We've reserved your slot.")
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
        .accessibilityElement(children: .contain)
    }

    // MARK: - Celebration

    private var celebration: some View {
        ZStack {
            // Soft expanding ring
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
                row(title: "Experience", value: booking.item.name)
                Divider().overlay(SBColor.border)
                row(title: "When", value: "\(booking.dateLabel()) · \(booking.slot.rangeLabel())")
                Divider().overlay(SBColor.border)
                row(title: "Duration", value: booking.durationLabel)
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

    // MARK: - Animation

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

#Preview("Success — Light") {
    let item = MockItems.catalog[1]
    let day = Calendar.current.startOfDay(for: Date())
    let slot = MockSlots.slots(for: day, itemID: item.id).first { $0.isAvailable }!
    let booking = Booking.make(
        item: item,
        slot: slot,
        date: day,
        guestName: "Alex Rivera",
        phoneDigits: "5551234567"
    )

    BookingSuccessView(booking: booking, onViewBookings: {}, onBookAnother: {})
}

#Preview("Success — Dark") {
    let item = MockItems.catalog[0]
    let day = Calendar.current.startOfDay(for: Date())
    let slot = MockSlots.slots(for: day, itemID: item.id).first { $0.isAvailable }!
    let booking = Booking.make(
        item: item,
        slot: slot,
        date: day,
        guestName: "Sam Chen",
        phoneDigits: "5559876543"
    )

    BookingSuccessView(booking: booking, onViewBookings: {}, onBookAnother: {})
        .preferredColorScheme(.dark)
}
