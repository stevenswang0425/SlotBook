//
//  MyBookingsView.swift
//  SlotBook
//
//  My Bookings tab — Upcoming / Past, cards, detail navigation, cancel.
//  Iteration 5: management polish + court detail + store-synced availability.
//

import SwiftUI

struct MyBookingsView: View {
    @Environment(\.bookingStore) private var bookingStore
    @Environment(\.appNavigation) private var appNavigation
    @Environment(\.themeManager) private var themeManager
    @State private var viewModel: BookingsViewModel?

    var body: some View {
        NavigationStack {
            ZStack {
                SBColor.background.ignoresSafeArea()

                if let viewModel {
                    content(viewModel)
                } else {
                    Color.clear
                }
            }
            .navigationTitle("My Bookings")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: CourtBooking.self) { booking in
                CourtBookingDetailView(
                    bookingID: booking.id,
                    viewModel: viewModel
                )
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = BookingsViewModel(store: bookingStore)
                }
                viewModel?.refreshClock()
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ viewModel: BookingsViewModel) -> some View {
        // Observe store mutations (book / cancel) for list refresh.
        let _ = bookingStore.bookings
        let _ = bookingStore.courtBookings
        let _ = bookingStore.reservationEpoch

        VStack(spacing: 0) {
            BookingsSegmentControl(
                selection: segmentBinding(viewModel),
                upcomingCount: viewModel.upcomingCount,
                pastCount: viewModel.pastCount
            )
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.xs)
            .padding(.bottom, Spacing.md)

            if viewModel.isEmpty {
                emptyState(for: viewModel.selectedSegment)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                bookingsList(viewModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: viewModel.selectedSegment)
        .animation(
            .spring(response: 0.36, dampingFraction: 0.86),
            value: listIdentity(viewModel)
        )
        .overlay(alignment: .bottom) {
            if let message = viewModel.toastMessage {
                ToastBanner(
                    message: message,
                    style: viewModel.toastIsError ? .warning : .success
                )
                .padding(.bottom, Spacing.xl)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onTapGesture { viewModel.dismissToast() }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: viewModel.toastMessage)
        .alert(
            viewModel.cancelAlertTitle,
            isPresented: cancelAlertBinding(viewModel)
        ) {
            Button("Keep booking", role: .cancel) {
                viewModel.dismissCancelConfirmation()
            }
            Button("Cancel booking", role: .destructive) {
                Task { await viewModel.confirmCancel() }
            }
        } message: {
            Text(viewModel.cancelAlertMessage)
        }
    }

    private func listIdentity(_ viewModel: BookingsViewModel) -> String {
        let court = viewModel.displayedCourtBookings.map {
            "\($0.id.uuidString):\($0.status.rawValue)"
        }.joined(separator: ",")
        let market = viewModel.displayedBookings.map {
            "\($0.id.uuidString):\($0.status.rawValue)"
        }.joined(separator: ",")
        return court + "|" + market
    }

    // MARK: - List

    private func bookingsList(_ viewModel: BookingsViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(viewModel.displayedCourtBookings) { booking in
                    NavigationLink(value: booking) {
                        CourtBookingRowCard(
                            booking: booking,
                            displayStatus: booking.displayStatus(now: viewModel.now),
                            showsChevron: true
                        )
                    }
                    .buttonStyle(BookingCardPressStyle())
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .scale(scale: 0.96))
                        )
                    )
                }

                ForEach(viewModel.displayedBookings) { booking in
                    BookingRowCard(
                        booking: booking,
                        displayStatus: booking.displayStatus(now: viewModel.now),
                        showsCancel: viewModel.selectedSegment == .upcoming
                            && booking.isUpcoming(now: viewModel.now),
                        isCancelling: viewModel.isCancelling
                            && viewModel.bookingPendingCancel?.id == booking.id,
                        onCancel: { viewModel.requestCancel(booking) }
                    )
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .scale(scale: 0.96))
                        )
                    )
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Empty

    private func emptyState(for segment: BookingsSegment) -> some View {
        let config = emptyConfig(for: segment)

        return EmptyStateView(
            systemImage: config.symbol,
            title: config.title,
            message: config.message,
            actionTitle: segment == .upcoming ? "Discover clubs" : nil,
            action: segment == .upcoming ? { appNavigation.openHome() } : nil
        )
        .padding(.bottom, Spacing.xxl)
    }

    private func emptyConfig(for segment: BookingsSegment) -> (symbol: String, title: String, message: String) {
        switch segment {
        case .upcoming:
            return (
                "sportscourt",
                "No upcoming bookings",
                "Book a court and it will appear here with the time and reference code."
            )
        case .past:
            return (
                "clock.arrow.circlepath",
                "No past bookings",
                "Completed and cancelled reservations will show up in this list."
            )
        }
    }

    // MARK: - Bindings

    private func segmentBinding(_ viewModel: BookingsViewModel) -> Binding<BookingsSegment> {
        Binding(
            get: { viewModel.selectedSegment },
            set: { viewModel.selectSegment($0) }
        )
    }

    private func cancelAlertBinding(_ viewModel: BookingsViewModel) -> Binding<Bool> {
        Binding(
            get: { viewModel.showsCancelConfirmation },
            set: { presented in
                if !presented {
                    viewModel.dismissCancelConfirmation()
                }
            }
        )
    }
}

// MARK: - Press style

private struct BookingCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Court row card

struct CourtBookingRowCard: View {
    let booking: CourtBooking
    var displayStatus: BookingDisplayStatus
    /// List mode shows a chevron; detail owns cancel.
    var showsChevron: Bool = false

    private var accent: Color {
        if let club = MockData.club(id: booking.clubId) {
            return club.primaryColor.swiftUIColor
        }
        return SBColor.success
    }

    private var clubImageName: String {
        MockData.club(id: booking.clubId)?.imageName ?? "figure.badminton"
    }

    var body: some View {
        CardView(padding: Spacing.md, cornerRadius: Radius.lg) {
            HStack(alignment: .top, spacing: Spacing.md) {
                artwork

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(booking.clubName ?? "Court booking")
                            .sbFontHeadline()
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: Spacing.xs)

                        BookingStatusBadge(status: displayStatus)
                    }

                    Text(booking.dateTimeLabel())
                        .sbFontCaption()
                        .lineLimit(2)

                    HStack(spacing: Spacing.xs) {
                        Label(booking.durationLabel, systemImage: "hourglass")
                        Text("·")
                            .foregroundStyle(SBColor.textTertiary)
                        Text(booking.referenceCode)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SBColor.textTertiary)
                    .padding(.top, 2)
                }

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SBColor.textTertiary)
                        .padding(.top, 4)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(booking.clubName ?? "Court"), \(booking.dateTimeLabel()), \(booking.durationLabel), \(displayStatus.title), reference \(booking.referenceCode)"
        )
        .accessibilityHint(showsChevron ? "Opens booking details" : "")
    }

    private var artwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.92), accent.opacity(0.48)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: clubImageName)
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(width: 56, height: 56)
        .opacity(displayStatus == .cancelled ? 0.55 : 1)
        .accessibilityHidden(true)
    }
}

// MARK: - Marketplace row card

struct BookingRowCard: View {
    let booking: Booking
    var displayStatus: BookingDisplayStatus
    var showsCancel: Bool = false
    var isCancelling: Bool = false
    var onCancel: (() -> Void)? = nil

    var body: some View {
        CardView(padding: Spacing.md, cornerRadius: Radius.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    artwork

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(booking.item.name)
                                .sbFontHeadline()
                                .lineLimit(2)

                            Spacer(minLength: Spacing.xs)

                            BookingStatusBadge(status: displayStatus)
                        }

                        Text(booking.dateTimeLabel())
                            .sbFontCaption()

                        Text("\(booking.durationLabel) · \(booking.referenceCode)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(SBColor.textTertiary)
                            .padding(.top, 2)
                    }
                }

                if showsCancel {
                    Divider().overlay(SBColor.border)

                    Button(role: .destructive) {
                        onCancel?()
                    } label: {
                        HStack {
                            if isCancelling {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text(isCancelling ? "Cancelling…" : "Cancel Booking")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(SBColor.destructive)
                        .padding(.vertical, Spacing.xs)
                    }
                    .buttonStyle(SBPressableButtonStyle())
                    .disabled(isCancelling)
                    .accessibilityLabel("Cancel booking for \(booking.item.name)")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "\(booking.item.name), \(booking.dateTimeLabel()), \(displayStatus.title), reference \(booking.referenceCode)"
        )
    }

    private var artwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            booking.item.color.swiftUIColor.opacity(0.9),
                            booking.item.color.swiftUIColor.opacity(0.5),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: booking.item.imageName)
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(.white)
        }
        .frame(width: 56, height: 56)
        .opacity(displayStatus == .cancelled ? 0.55 : 1)
    }
}

// MARK: - Previews

#Preview("My Bookings — Court seeded") {
    let store = BookingStore()
    store.seedCourtPreviewData()

    return MyBookingsView()
        .bookingStore(store)
        .appNavigation(AppNavigation())
        .themeManager(ThemeManager())
}

#Preview("My Bookings — Empty") {
    MyBookingsView()
        .bookingStore(BookingStore())
        .appNavigation(AppNavigation())
        .themeManager(ThemeManager())
}

#Preview("My Bookings — Dark") {
    let store = BookingStore()
    store.seedCourtPreviewData()

    return MyBookingsView()
        .bookingStore(store)
        .appNavigation(AppNavigation())
        .themeManager(ThemeManager())
        .preferredColorScheme(.dark)
}

#Preview("Court card") {
    let start = Date().addingTimeInterval(86_400)
    let booking = CourtBooking.make(
        clubId: MockData.torontoClubId,
        clubName: "Toronto Badminton Club",
        courtId: UUID(),
        courtNumber: 3,
        slotId: UUID(),
        start: start,
        end: start.addingTimeInterval(3_600),
        durationMinutes: 60,
        guestName: "Alex",
        phoneDigits: "5551234567"
    )

    return CourtBookingRowCard(
        booking: booking,
        displayStatus: .upcoming,
        showsChevron: true
    )
    .padding()
    .background(SBColor.background)
}
