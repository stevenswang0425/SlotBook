//
//  MyBookingsView.swift
//  SlotBook
//
//  My Bookings tab: Upcoming / Past segments, cancel flow, empty states.
//

import SwiftUI

struct MyBookingsView: View {
    @Environment(\.bookingStore) private var bookingStore
    @Environment(\.appNavigation) private var appNavigation
    @State private var viewModel: BookingsViewModel?

    var body: some View {
        NavigationStack {
            ZStack {
                SBColor.background.ignoresSafeArea()

                if let viewModel {
                    content(viewModel)
                } else {
                    // Brief placeholder while the view model attaches to the store.
                    Color.clear
                }
            }
            .navigationTitle("My Bookings")
            .navigationBarTitleDisplayMode(.large)
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
        // Touch store properties so list re-renders when bookings change.
        let _ = bookingStore.bookings
        let _ = bookingStore.reservedSlotIDs

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
        .animation(.spring(response: 0.36, dampingFraction: 0.86), value: viewModel.displayedBookings.map(\.id))
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
            "Cancel booking?",
            isPresented: cancelAlertBinding(viewModel)
        ) {
            Button("Keep booking", role: .cancel) {
                viewModel.dismissCancelConfirmation()
            }
            Button("Cancel booking", role: .destructive) {
                Task {
                    await viewModel.confirmCancel()
                }
            }
        } message: {
            if let booking = viewModel.bookingPendingCancel {
                Text(
                    "\(booking.item.name) on \(booking.dateTimeLabel()) will be cancelled and the time slot will become available again."
                )
            }
        }
    }

    // MARK: - List

    private func bookingsList(_ viewModel: BookingsViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(viewModel.displayedBookings) { booking in
                    BookingRowCard(
                        booking: booking,
                        displayStatus: booking.displayStatus(now: viewModel.now),
                        showsCancel: viewModel.selectedSegment == .upcoming
                            && booking.isUpcoming(now: viewModel.now),
                        isCancelling: viewModel.isCancelling
                            && viewModel.bookingPendingCancel?.id == booking.id,
                        onCancel: {
                            viewModel.requestCancel(booking)
                        }
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

        return VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(SBColor.chipBackground)
                    .frame(width: 88, height: 88)

                Image(systemName: config.symbol)
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(SBColor.textTertiary)
                    .symbolRenderingMode(.hierarchical)
            }

            Text(config.title)
                .sbFontHeadline()

            Text(config.message)
                .sbFontBody()
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)

            if segment == .upcoming {
                Button {
                    appNavigation.openHome()
                } label: {
                    Text("Browse experiences")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SBColor.primary)
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding(.bottom, Spacing.xxxl)
        .accessibilityElement(children: .combine)
    }

    private func emptyConfig(for segment: BookingsSegment) -> (symbol: String, title: String, message: String) {
        switch segment {
        case .upcoming:
            return (
                "calendar.badge.plus",
                "No upcoming bookings",
                "Reserve a slot and it will appear here with the time and details."
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

// MARK: - Row card

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

                        Text(booking.referenceCode)
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

#Preview("My Bookings — Seeded Light") {
    let store = BookingStore()
    store.seedPreviewData()

    return MyBookingsView()
        .bookingStore(store)
        .appNavigation(AppNavigation())
}

#Preview("My Bookings — Empty") {
    MyBookingsView()
        .bookingStore(BookingStore())
        .appNavigation(AppNavigation())
}

#Preview("My Bookings — Dark") {
    let store = BookingStore()
    store.seedPreviewData()

    return MyBookingsView()
        .bookingStore(store)
        .appNavigation(AppNavigation())
        .preferredColorScheme(.dark)
}

#Preview("Booking Card — Upcoming") {
    let store = BookingStore()
    store.seedPreviewData()
    let booking = store.upcomingBookings().first!

    return BookingRowCard(
        booking: booking,
        displayStatus: .upcoming,
        showsCancel: true,
        onCancel: {}
    )
    .padding()
    .background(SBColor.background)
}

#Preview("Booking Card — Past") {
    let store = BookingStore()
    store.seedPreviewData()
    let booking = store.pastBookings().first!

    return BookingRowCard(
        booking: booking,
        displayStatus: booking.displayStatus(),
        showsCancel: false
    )
    .padding()
    .background(SBColor.background)
}
