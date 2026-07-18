//
//  BookingFlowView.swift
//  SlotBook
//
//  Multi-step booking sheet: form → confirm → success.
//

import SwiftUI

struct BookingFlowView: View {
    @State private var viewModel: BookingViewModel
    @Environment(\.bookingStore) private var bookingStore
    @Environment(\.appNavigation) private var appNavigation
    @Environment(\.dismiss) private var dismiss

    /// Called after a successful booking so the detail screen can mark the slot booked.
    var onBookingCompleted: ((Booking) -> Void)?

    init(
        item: Item,
        slot: TimeSlot,
        date: Date,
        onBookingCompleted: ((Booking) -> Void)? = nil
    ) {
        _viewModel = State(
            initialValue: BookingViewModel(item: item, slot: slot, date: date)
        )
        self.onBookingCompleted = onBookingCompleted
    }

    /// Preview / test injection.
    init(viewModel: BookingViewModel, onBookingCompleted: ((Booking) -> Void)? = nil) {
        _viewModel = State(initialValue: viewModel)
        self.onBookingCompleted = onBookingCompleted
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SBColor.background.ignoresSafeArea()

                Group {
                    switch viewModel.step {
                    case .form:
                        formStep
                            .transition(stepTransition)
                    case .confirm:
                        confirmStep
                            .transition(stepTransition)
                    case .success:
                        if let booking = viewModel.completedBooking {
                            BookingSuccessView(
                                booking: booking,
                                onViewBookings: handleViewBookings,
                                onBookAnother: handleBookAnother
                            )
                            .transition(stepTransition)
                        }
                    }
                }
                .animation(.spring(response: 0.38, dampingFraction: 0.88), value: viewModel.step)
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.step != .success {
                        Button("Close") { dismiss() }
                            .foregroundStyle(SBColor.primary)
                            .disabled(viewModel.isSubmitting)
                            .accessibilityHint("Dismisses the booking sheet")
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.step == .confirm {
                        Button {
                            viewModel.backToForm()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(SBColor.primary)
                        }
                        .disabled(viewModel.isSubmitting)
                        .accessibilityLabel("Back to form")
                    }
                }
            }
            .interactiveDismissDisabled(viewModel.isSubmitting || viewModel.step == .success)
            .onAppear {
                viewModel.attach(store: bookingStore)
            }
        }
        .presentationDetents(viewModel.step == .success ? [.large] : [.large, .medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Form

    private var formStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                BookingSummaryCard(
                    item: viewModel.item,
                    slot: viewModel.slot,
                    date: viewModel.date,
                    durationLabel: viewModel.durationLabel
                )

                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Your details")
                        .sbFontHeadline()

                    SBTextField(
                        title: "Name",
                        placeholder: "Full name",
                        text: nameBinding,
                        textContentType: .name,
                        error: viewModel.errors.name
                    )

                    SBTextField(
                        title: "Phone number",
                        placeholder: "(555) 123-4567",
                        text: phoneBinding,
                        keyboardType: .phonePad,
                        textContentType: .telephoneNumber,
                        error: viewModel.errors.phone,
                        autocapitalization: .never
                    )
                }

                if let submitError = viewModel.submitError {
                    Text(submitError)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SBColor.destructive)
                }

                PrimaryButton(
                    title: "Review booking",
                    isEnabled: true,
                    action: {
                        _ = viewModel.continueToConfirm()
                    }
                )
                .padding(.top, Spacing.xs)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Confirm

    private var confirmStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                Text("Please confirm your reservation. You can go back to edit details.")
                    .sbFontBody()

                BookingSummaryCard(
                    item: viewModel.item,
                    slot: viewModel.slot,
                    date: viewModel.date,
                    durationLabel: viewModel.durationLabel
                )

                CardView(showsShadow: false, showsBorder: true) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        confirmRow(title: "Guest", value: viewModel.guestName.trimmingCharacters(in: .whitespacesAndNewlines))
                        Divider().overlay(SBColor.border)
                        confirmRow(title: "Phone", value: viewModel.phoneDisplay)
                        Divider().overlay(SBColor.border)
                        confirmRow(title: "Duration", value: viewModel.durationLabel)
                    }
                }

                if let submitError = viewModel.submitError {
                    errorBanner(submitError)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                PrimaryButton(
                    title: viewModel.isSubmitting ? "Confirming…" : "Confirm Booking",
                    isLoading: viewModel.isSubmitting,
                    isEnabled: !viewModel.isSubmitting,
                    action: {
                        Task { await submit() }
                    }
                )
                .padding(.top, Spacing.xs)
                .accessibilityHint("Submits your booking for the selected time")

                if viewModel.lastSubmitError == .slotUnavailable {
                    SecondaryButton(
                        title: "Choose another time",
                        isEnabled: !viewModel.isSubmitting,
                        action: { dismiss() }
                    )
                } else {
                    SecondaryButton(
                        title: "Edit details",
                        isEnabled: !viewModel.isSubmitting,
                        action: viewModel.backToForm
                    )
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
    }

    // MARK: - Bindings

    private var nameBinding: Binding<String> {
        Binding(
            get: { viewModel.guestName },
            set: { viewModel.updateName($0) }
        )
    }

    private var phoneBinding: Binding<String> {
        Binding(
            get: { viewModel.phoneDisplay },
            set: { viewModel.updatePhone(fromFormatted: $0) }
        )
    }

    // MARK: - Actions

    private func submit() async {
        if let booking = await viewModel.confirmBooking() {
            // Final race check at the store boundary (remote pulse during success hop).
            if bookingStore.isSlotReserved(booking.slot.id) {
                viewModel.markLateSlotConflict()
                return
            }
            bookingStore.add(booking)
            onBookingCompleted?(booking)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(SBColor.destructive)
                .accessibilityHidden(true)

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SBColor.destructive)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(SBColor.destructive.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }

    private func handleViewBookings() {
        dismiss()
        // Allow sheet dismiss animation to start before tab switch.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            appNavigation.openBookings()
        }
    }

    private func handleBookAnother() {
        dismiss()
    }

    // MARK: - Chrome

    private var navigationTitle: String {
        switch viewModel.step {
        case .form: return "Book slot"
        case .confirm: return "Confirm"
        case .success: return "Confirmed"
        }
    }

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        )
    }

    private func confirmRow(title: String, value: String) -> some View {
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
}

// MARK: - Previews

#Preview("Booking Flow — Form") {
    let item = MockItems.catalog[1]
    let day = Calendar.current.startOfDay(for: Date())
    let slot = MockSlots.slots(for: day, itemID: item.id).first { $0.isAvailable }!

    BookingFlowView(item: item, slot: slot, date: day)
        .bookingStore(BookingStore())
        .appNavigation(AppNavigation())
}

#Preview("Booking Flow — Confirm") {
    let item = MockItems.catalog[0]
    let day = Calendar.current.startOfDay(for: Date())
    let slot = MockSlots.slots(for: day, itemID: item.id).first { $0.isAvailable }!
    let vm = BookingViewModel(item: item, slot: slot, date: day)
    vm.guestName = "Alex Rivera"
    vm.phoneDigits = "5551234567"
    vm.step = .confirm

    return BookingFlowView(viewModel: vm)
        .bookingStore(BookingStore())
        .appNavigation(AppNavigation())
}

#Preview("Booking Flow — Dark") {
    let item = MockItems.catalog[2]
    let day = Calendar.current.startOfDay(for: Date())
    let slot = MockSlots.slots(for: day, itemID: item.id).first { $0.isAvailable }!

    BookingFlowView(item: item, slot: slot, date: day)
        .bookingStore(BookingStore())
        .appNavigation(AppNavigation())
        .preferredColorScheme(.dark)
}
