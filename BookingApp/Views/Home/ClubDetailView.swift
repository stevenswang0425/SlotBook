//
//  ClubDetailView.swift
//  SlotBook
//
//  Club detail — hero, stats, date + duration, hidden-court availability grid.
//

import SwiftUI

struct ClubDetailView: View {
    let club: BadmintonClub

    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.repositories) private var repositories
    @Environment(\.bookingStore) private var bookingStore
    @Environment(\.appNavigation) private var appNavigation
    @Environment(\.userSession) private var userSession

    @State private var viewModel: ClubDetailViewModel?

    private var accent: Color { club.primaryColor.swiftUIColor }

    var body: some View {
        ZStack {
            SBColor.background.ignoresSafeArea()

            if let viewModel {
                detailContent(viewModel)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(club.name)
                    .font(.system(.subheadline, design: .default).weight(.semibold))
                    .foregroundStyle(SBColor.textPrimary)
                    .lineLimit(1)
            }
        }
        .task {
            if viewModel == nil {
                let vm = ClubDetailViewModel(
                    club: club,
                    clubRepository: repositories.clubs
                )
                vm.attach(store: bookingStore)
                viewModel = vm
            }
            await viewModel?.load()
            themeManager.applyClubTheme(club)
        }
        .onChange(of: bookingStore.reservationEpoch) { _, _ in
            viewModel?.handleStoreReservationChange()
        }
        .onDisappear {
            viewModel?.onDisappear()
            themeManager.clearClubTheme()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func detailContent(_ viewModel: ClubDetailViewModel) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    hero
                    headerBlock
                    statsRow(viewModel)
                    amenitiesSection

                    bookingSection(viewModel)
                        .id("available-slots")

                    PrimaryButton(
                        title: viewModel.bookButtonTitle,
                        isEnabled: viewModel.canContinueBooking
                    ) {
                        viewModel.bookCourtTapped()
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .onChange(of: viewModel.selectedOptionID) { _, newValue in
                if newValue != nil {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo("available-slots", anchor: .center)
                    }
                }
            }
        }
        .sheet(isPresented: bookingSheetBinding(viewModel)) {
            if let draft = viewModel.bookingDraft {
                CourtBookingFlowView(
                    draft: draft,
                    clubRepository: repositories.clubs,
                    onBookingCompleted: { booking in
                        viewModel.handleBookingCompleted(booking)
                    }
                )
                .themeManager(themeManager)
                .bookingStore(bookingStore)
                .appNavigation(appNavigation)
                .userSession(userSession)
            }
        }
        .overlay(alignment: .top) {
            if viewModel.showToast, let message = viewModel.toastMessage {
                ToastBanner(message: message, style: .info)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.sm)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: message) {
                        try? await Task.sleep(for: .seconds(2.6))
                        withAnimation(.easeOut(duration: 0.25)) {
                            viewModel.dismissToast()
                        }
                    }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: viewModel.showToast)
    }

    private func bookingSheetBinding(_ viewModel: ClubDetailViewModel) -> Binding<Bool> {
        Binding(
            get: { viewModel.isBookingSheetPresented },
            set: { presented in
                if !presented { viewModel.dismissBookingSheet() }
                else { viewModel.isBookingSheetPresented = true }
            }
        )
    }

    // MARK: - Hero

    private var hero: some View {
        ZStack {
            LinearGradient(
                colors: [
                    accent.opacity(0.95),
                    accent.opacity(0.5),
                    accent.opacity(0.3),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 180, height: 180)
                .offset(x: 100, y: -40)

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 90, height: 90)
                .offset(x: -90, y: 50)

            Image(systemName: club.imageName)
                .font(.system(size: 72, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.95))
                .symbolRenderingMode(.hierarchical)
                .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        }
        .frame(height: 220)
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

    // MARK: - Header

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(club.name)
                .font(.system(.title, design: .default).weight(.bold))
                .foregroundStyle(SBColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Label(club.locationLabel, systemImage: "mappin.and.ellipse")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SBColor.textSecondary)

            HStack(spacing: Spacing.sm) {
                metaChip(icon: "dollarsign.circle", text: club.priceLabel)
                if club.isIndoor {
                    metaChip(icon: "building.2", text: "Indoor")
                }
                if club.hasCoaching {
                    metaChip(icon: "figure.badminton", text: "Coaching")
                }
            }

            Text(club.description)
                .sbFontBody()
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Spacing.xxs)
        }
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: - Stats

    private func statsRow(_ viewModel: ClubDetailViewModel) -> some View {
        HStack(spacing: Spacing.sm) {
            statCard(icon: "sportscourt.fill", title: "Total Courts", value: viewModel.courtsStatLabel)
            statCard(icon: "clock", title: "Opening Hours", value: viewModel.openingHoursLabel)
        }
        .padding(.horizontal, Spacing.xl)
    }

    private func statCard(icon: String, title: String, value: String) -> some View {
        CardView(padding: Spacing.md, cornerRadius: Radius.md, showsShadow: false, showsBorder: true) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accent)
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SBColor.textSecondary)
                }
                Text(value)
                    .font(.system(.subheadline, design: .default).weight(.semibold))
                    .foregroundStyle(SBColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.85)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Amenities

    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Amenities")
                .sbFontHeadline()
                .padding(.horizontal, Spacing.xl)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(club.amenities, id: \.self) { amenity in
                        Text(amenity)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(accent.opacity(0.12))
                            )
                    }
                }
                .padding(.horizontal, Spacing.xl)
            }
        }
    }

    // MARK: - Booking section (date / duration / slots)

    private func bookingSection(_ viewModel: ClubDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Book a court")
                    .sbFontHeadline()
                Text("We’ll assign a free court automatically — no court numbers to pick.")
                    .sbFontCaption()
            }
            .padding(.horizontal, Spacing.xl)

            // Date
            VStack(alignment: .leading, spacing: Spacing.xs) {
                sectionLabel("Date")
                DateSelectorBar(
                    days: viewModel.days,
                    selectedDate: viewModel.selectedDate,
                    onSelect: { viewModel.selectDate($0) }
                )
            }

            // Duration
            VStack(alignment: .leading, spacing: Spacing.xs) {
                sectionLabel("Duration")
                CourtDurationPicker(
                    selection: viewModel.selectedDuration,
                    onSelect: { viewModel.selectDuration($0) }
                )
                .padding(.horizontal, Spacing.xl)
            }

            // Slots
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    sectionLabel("Available times")
                    Spacer()
                    Text(viewModel.availabilitySummary)
                        .font(.system(.caption, design: .default).weight(.medium))
                        .foregroundStyle(SBColor.textTertiary)
                        .padding(.trailing, Spacing.xl)
                        .accessibilityLabel(viewModel.availabilitySummary)
                }

                CourtSlotGrid(
                    options: viewModel.startOptions,
                    selectedID: viewModel.selectedOptionID,
                    isLoading: viewModel.isLoadingSlots,
                    onSelect: { viewModel.selectOption($0) }
                )
                .padding(.horizontal, Spacing.xl)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(.subheadline, design: .default).weight(.semibold))
            .foregroundStyle(SBColor.textPrimary)
            .padding(.horizontal, Spacing.xl)
    }

    // MARK: - Chips

    private func metaChip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous).fill(accent.opacity(0.12))
        )
    }
}

// MARK: - Previews

#Preview("Club Detail — Toronto") {
    NavigationStack {
        ClubDetailView(club: MockData.clubs[0])
    }
    .themeManager(ThemeManager())
    .repositories(.makeDefault())
    .bookingStore(BookingStore())
}

#Preview("Club Detail — Willowdale Dark") {
    NavigationStack {
        ClubDetailView(club: MockData.clubs[1])
    }
    .themeManager(ThemeManager())
    .repositories(.makeDefault())
    .bookingStore(BookingStore())
    .preferredColorScheme(.dark)
}

#Preview("Club Detail — North York") {
    NavigationStack {
        ClubDetailView(club: MockData.clubs[2])
    }
    .themeManager(ThemeManager())
    .repositories(.makeDefault())
    .bookingStore(BookingStore())
}
