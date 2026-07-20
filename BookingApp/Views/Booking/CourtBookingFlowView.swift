//
//  CourtBookingFlowView.swift
//  SlotBook
//
//  Multi-step court booking sheet: form → confirm → success.
//  Also known as the Booking Form surface for Iteration 4.
//

import SwiftUI

struct CourtBookingFlowView: View {
    @State private var viewModel: CourtBookingViewModel

    @Environment(\.bookingStore) private var bookingStore
    @Environment(\.appNavigation) private var appNavigation
    @Environment(\.userSession) private var userSession
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    /// Called after a successful booking so Club Detail can refresh availability.
    var onBookingCompleted: ((CourtBooking) -> Void)?

    init(
        draft: CourtBookingDraft,
        clubRepository: any ClubRepository = MockClubRepository(),
        onBookingCompleted: ((CourtBooking) -> Void)? = nil
    ) {
        _viewModel = State(
            initialValue: CourtBookingViewModel(
                draft: draft,
                clubRepository: clubRepository
            )
        )
        self.onBookingCompleted = onBookingCompleted
    }

    /// Preview / test injection.
    init(
        viewModel: CourtBookingViewModel,
        onBookingCompleted: ((CourtBooking) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onBookingCompleted = onBookingCompleted
    }

    private var accent: Color {
        viewModel.club.primaryColor.swiftUIColor
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
                            CourtBookingSuccessView(
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
                            .foregroundStyle(themeManager.primary(for: colorScheme))
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
                                .foregroundStyle(themeManager.primary(for: colorScheme))
                        }
                        .disabled(viewModel.isSubmitting)
                        .accessibilityLabel("Back to form")
                    }
                }
            }
            .interactiveDismissDisabled(viewModel.isSubmitting || viewModel.step == .success)
            .onAppear {
                viewModel.attach(store: bookingStore)
                viewModel.prefill(from: userSession)
                themeManager.applyClubTheme(viewModel.club)
            }
        }
        .presentationDetents(viewModel.step == .success ? [.large] : [.large, .medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Form

    private var formStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                courtSummaryCard

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

                cancellationPolicy

                if let submitError = viewModel.submitError {
                    Text(submitError)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SBColor.destructive)
                }

                PrimaryButton(
                    title: "Review booking",
                    action: { _ = viewModel.continueToConfirm() }
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

                courtSummaryCard

                CardView(showsShadow: false, showsBorder: true) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        confirmRow(
                            title: "Guest",
                            value: viewModel.guestName.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        Divider().overlay(SBColor.border)
                        confirmRow(title: "Phone", value: viewModel.phoneDisplay)
                        Divider().overlay(SBColor.border)
                        confirmRow(title: "Duration", value: viewModel.durationLabel)
                        Divider().overlay(SBColor.border)
                        confirmRow(title: "Estimated", value: viewModel.estimatedPriceLabel)
                    }
                }

                CardView(showsShadow: false, showsBorder: true) {
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: "sportscourt.fill")
                            .foregroundStyle(accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Court assigned automatically")
                                .font(.system(.subheadline, design: .default).weight(.semibold))
                                .foregroundStyle(SBColor.textPrimary)
                            Text("We hold the next free court for this time. You won’t need a court number.")
                                .sbFontCaption()
                        }
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
                    action: { Task { await submit() } }
                )
                .padding(.top, Spacing.xs)
                .accessibilityHint("Submits your court booking")

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

    // MARK: - Shared cards

    private var courtSummaryCard: some View {
        CardView(showsShadow: true) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [accent.opacity(0.9), accent.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Image(systemName: viewModel.club.imageName)
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.club.name)
                            .sbFontHeadline()
                            .lineLimit(2)
                        Text(viewModel.club.shortAddressLabel)
                            .sbFontCaption()
                            .lineLimit(1)
                    }
                }

                Divider().overlay(SBColor.border)

                summaryLine(icon: "calendar", text: dateLabel)
                summaryLine(icon: "clock", text: viewModel.option.rangeLabel())
                summaryLine(icon: "hourglass", text: viewModel.durationLabel)
                summaryLine(icon: "dollarsign.circle", text: viewModel.estimatedPriceLabel)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(viewModel.club.name), \(dateLabel), \(viewModel.option.rangeLabel()), \(viewModel.durationLabel)"
        )
    }

    private var cancellationPolicy: some View {
        CardView(showsShadow: false, showsBorder: true) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(accent)
                    .font(.system(size: 16))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cancellation")
                        .font(.system(.subheadline, design: .default).weight(.semibold))
                        .foregroundStyle(SBColor.textPrimary)
                    Text(
                        "Free cancellation up to 2 hours before your start time. "
                            + "We hold your court quietly until then — no pressure."
                    )
                    .sbFontCaption()
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func summaryLine(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 18)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SBColor.textPrimary)
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

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: viewModel.date)
    }

    // MARK: - Actions

    private func submit() async {
        if let booking = await viewModel.confirmBooking() {
            bookingStore.addCourtBooking(booking)
            bookingStore.setPendingCourtDraft(nil)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            appNavigation.openBookings()
        }
    }

    private func handleBookAnother() {
        dismiss()
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

    private var navigationTitle: String {
        switch viewModel.step {
        case .form: return "Book court"
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
}

// MARK: - Convenience alias

/// Iteration 4 deliverable name — same multi-step court booking flow.
typealias BookingFormView = CourtBookingFlowView

// MARK: - Previews

#Preview("Court booking — Form") {
    let day = Calendar.current.startOfDay(for: Date().addingTimeInterval(86_400))
    let options = MockData.findAvailableSlots(
        clubId: MockData.torontoClubId,
        date: day,
        durationMinutes: 60
    )
    let option = options.first(where: \.isAvailable)!
    let draft = CourtBookingDraft(club: MockData.clubs[0], option: option, date: day)

    return CourtBookingFlowView(draft: draft)
        .bookingStore(BookingStore())
        .appNavigation(AppNavigation())
        .userSession(UserSession())
        .themeManager(ThemeManager())
        .repositories(.makeDefault())
}

#Preview("Court booking — Confirm") {
    let day = Calendar.current.startOfDay(for: Date().addingTimeInterval(86_400))
    let options = MockData.findAvailableSlots(
        clubId: MockData.torontoClubId,
        date: day,
        durationMinutes: 60
    )
    let option = options.first(where: \.isAvailable)!
    let draft = CourtBookingDraft(club: MockData.clubs[0], option: option, date: day)
    let vm = CourtBookingViewModel(draft: draft)
    vm.guestName = "Alex Rivera"
    vm.phoneDigits = "5551234567"
    vm.step = .confirm

    return CourtBookingFlowView(viewModel: vm)
        .bookingStore(BookingStore())
        .appNavigation(AppNavigation())
        .userSession(UserSession())
        .themeManager(ThemeManager())
}

#Preview("Court booking — Dark") {
    let day = Calendar.current.startOfDay(for: Date().addingTimeInterval(86_400))
    let options = MockData.findAvailableSlots(
        clubId: MockData.willowdaleClubId,
        date: day,
        durationMinutes: 45
    )
    let option = options.first(where: \.isAvailable)!
    let draft = CourtBookingDraft(club: MockData.clubs[1], option: option, date: day)

    return CourtBookingFlowView(draft: draft)
        .bookingStore(BookingStore())
        .appNavigation(AppNavigation())
        .userSession(UserSession())
        .themeManager(ThemeManager())
        .preferredColorScheme(.dark)
}
