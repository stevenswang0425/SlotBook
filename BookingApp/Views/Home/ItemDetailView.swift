//
//  ItemDetailView.swift
//  SlotBook
//
//  Item Detail: hero, favorite, date strip, time-slot grid, booking CTA.
//

import SwiftUI

/// Destination pushed when a user taps an item card.
struct ItemDetailView: View {
    @Environment(\.bookingStore) private var bookingStore
    @State private var viewModel: ItemDetailViewModel

    init(item: Item) {
        _viewModel = State(initialValue: ItemDetailViewModel(item: item))
    }

    /// Preview / testing injection.
    init(viewModel: ItemDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            SBColor.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    heroHeader
                    itemInfo
                    dateSection
                    slotsSection
                    legend
                }
                .padding(.bottom, 120) // room for sticky booking bar
            }
            .scrollIndicators(.hidden)
            .refreshable {
                await viewModel.refresh()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bookingBar
        }
        .overlay(alignment: .top) {
            if let message = viewModel.liveToastMessage {
                ToastBanner(
                    message: message,
                    style: toastStyle(for: viewModel.liveToastStyle)
                )
                .padding(.top, Spacing.sm)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onTapGesture { viewModel.dismissLiveToast() }
                .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: viewModel.liveToastMessage)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                favoriteButton
            }
        }
        .sheet(isPresented: bookingSheetBinding) {
            if let context = viewModel.bookingContext {
                BookingFlowView(
                    item: context.item,
                    slot: context.slot,
                    date: context.date,
                    onBookingCompleted: { booking in
                        viewModel.applySuccessfulBooking(slotID: booking.slot.id)
                    }
                )
            }
        }
        .onAppear {
            viewModel.attach(store: bookingStore)
            viewModel.onAppear()
        }
        .onDisappear { viewModel.onDisappear() }
        // Instant cross-screen sync: user bookings, cancels, and remote simulator pulses.
        .onChange(of: bookingStore.reservationEpoch) { _, _ in
            viewModel.handleStoreReservationChange()
        }
    }

    private func toastStyle(for style: ItemDetailViewModel.LiveToastStyle) -> ToastBannerStyle {
        switch style {
        case .info: return .info
        case .warning: return .warning
        case .success: return .success
        }
    }

    /// Keeps `bookingContext` in sync when the sheet is dismissed by swipe/close.
    private var bookingSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isBookingSheetPresented },
            set: { presented in
                if presented {
                    viewModel.isBookingSheetPresented = true
                } else {
                    viewModel.dismissBookingSheet()
                }
            }
        )
    }

    // MARK: - Hero

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    viewModel.item.color.swiftUIColor.opacity(0.95),
                    viewModel.item.color.swiftUIColor.opacity(0.55),
                    viewModel.item.color.swiftUIColor.opacity(0.35),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 160, height: 160)
                .offset(x: 140, y: -40)

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 100, height: 100)
                .offset(x: -30, y: 40)

            VStack(spacing: Spacing.md) {
                Image(systemName: viewModel.item.imageName)
                    .font(.system(size: 68, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.95))
                    .symbolRenderingMode(.hierarchical)
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.xxl)
                    .padding(.bottom, Spacing.xl)
            }
        }
        .frame(height: 240)
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

    // MARK: - Info

    private var itemInfo: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            CategoryBadge(
                category: viewModel.item.category,
                accent: viewModel.item.color.swiftUIColor
            )

            Text(viewModel.item.name)
                .sbFontTitle()
                .fixedSize(horizontal: false, vertical: true)

            Text(viewModel.item.description)
                .sbFontBody()
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Spacing.xxs)
        }
        .padding(.horizontal, Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityHeading(.h1)
    }

    // MARK: - Date

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(
                title: "Select a date",
                subtitle: "Next \(viewModel.days.count) days"
            )
            .accessibilityAddTraits(.isHeader)

            DateSelectorBar(
                days: viewModel.days,
                selectedDate: viewModel.selectedDate,
                onSelect: { date in
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        viewModel.selectDate(date)
                    }
                }
            )
        }
    }

    // MARK: - Slots

    private var slotsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(
                title: "Available times",
                subtitle: "30-minute slots"
            )

            if viewModel.isLoadingSlots {
                ProgressView()
                    .tint(SBColor.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xl)
                    .accessibilityLabel("Loading time slots")
            } else {
                TimeSlotGrid(
                    slots: viewModel.slots,
                    selectedSlotID: viewModel.selectedSlotID,
                    onSelect: viewModel.selectSlot
                )
                .animation(.easeInOut(duration: 0.28), value: viewModel.selectedDate)
                .animation(.spring(response: 0.28, dampingFraction: 0.84), value: viewModel.selectedSlotID)
                .animation(.easeInOut(duration: 0.35), value: viewModel.slots.map(\.availability))
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var legend: some View {
        HStack(spacing: Spacing.lg) {
            legendItem(color: SBColor.primary.opacity(0.45), style: .stroke, label: "Available")
            legendItem(color: SBColor.primary, style: .fill, label: "Selected")
            legendItem(color: SBColor.chipBackground, style: .fillMuted, label: "Booked")
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Legend: Available, Selected, Booked")
    }

    // MARK: - Booking bar

    private var bookingBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(SBColor.border)

            VStack(spacing: Spacing.sm) {
                if let slot = viewModel.selectedSlot {
                    HStack {
                        Text("Selected")
                            .sbFontCaption()
                        Spacer()
                        Text(slot.rangeLabel())
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SBColor.textPrimary)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                PrimaryButton(
                    title: viewModel.bookingButtonTitle,
                    isEnabled: viewModel.canBook,
                    action: viewModel.beginBooking
                )
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.md)
            .background(SBColor.background.opacity(0.96))
        }
        .animation(.easeInOut(duration: 0.22), value: viewModel.selectedSlotID)
    }

    // MARK: - Toolbar

    private var favoriteButton: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                viewModel.toggleFavorite()
            }
        } label: {
            Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(viewModel.isFavorite ? SBColor.destructive : SBColor.textPrimary)
                .symbolEffect(.bounce, value: viewModel.isFavorite)
        }
        .accessibilityLabel(viewModel.isFavorite ? "Remove from favorites" : "Add to favorites")
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .sbFontHeadline()
            Text(subtitle)
                .sbFontCaption()
        }
        .padding(.horizontal, Spacing.xl)
    }

    private enum LegendStyle {
        case stroke
        case fill
        case fillMuted
    }

    private func legendItem(color: Color, style: LegendStyle, label: String) -> some View {
        HStack(spacing: Spacing.xxs) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(style == .stroke ? Color.clear : color)
                .overlay {
                    if style == .stroke {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(color, lineWidth: 1.5)
                    }
                }
                .frame(width: 14, height: 14)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SBColor.textSecondary)
        }
    }
}

// MARK: - Previews

#Preview("Detail — Light") {
    NavigationStack {
        ItemDetailView(item: MockItems.catalog[1])
    }
    .brandTheme(.slotBook)
}

#Preview("Detail — Dark") {
    NavigationStack {
        ItemDetailView(item: MockItems.catalog[0])
    }
    .brandTheme(.slotBook)
    .preferredColorScheme(.dark)
}

#Preview("Detail — Slot Selected") {
    let item = MockItems.catalog[2]
    let vm = ItemDetailViewModel(item: item)
    if let first = vm.slots.first(where: \.isAvailable) {
        vm.selectSlot(first)
    }
    return NavigationStack {
        ItemDetailView(viewModel: vm)
    }
    .brandTheme(.slotBook)
}
