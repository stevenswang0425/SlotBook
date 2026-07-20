//
//  AdminBookingsListView.swift
//  SlotBook
//
//  Unified owner bookings list — filter by club, view detail, cancel.
//

import SwiftUI

struct AdminBookingsListView: View {
    @Bindable var viewModel: AdminStoreViewModel

    @Environment(\.bookingStore) private var bookingStore
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedBooking: AdminCourtBookingRow?
    @State private var pendingCancel: AdminCourtBookingRow?

    var body: some View {
        let _ = bookingStore.reservationEpoch
        let _ = bookingStore.courtBookings

        VStack(spacing: 0) {
            // Club filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(viewModel.clubFilterOptions, id: \.name) { option in
                        let selected = viewModel.bookingsClubFilter == option.id
                        SlotChip(
                            title: option.name,
                            isSelected: selected,
                            action: { viewModel.selectBookingsFilter(option.id) }
                        )
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.sm)
            }

            BookingsSegmentControl(
                selection: segmentBinding,
                upcomingCount: upcomingCount,
                pastCount: pastCount
            )
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.md)

            if viewModel.displayedAdminBookings.isEmpty {
                EmptyStateView(
                    systemImage: "calendar",
                    title: "No bookings",
                    message: viewModel.bookingsSegment == .upcoming
                        ? "Upcoming reservations for the selected clubs will show here."
                        : "Past and cancelled bookings will appear here."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(viewModel.displayedAdminBookings) { row in
                            Button {
                                selectedBooking = row
                            } label: {
                                AdminBookingRowCard(row: row, showsCourt: true)
                            }
                            .buttonStyle(SBPressableButtonStyle())
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.xxl)
                }
            }
        }
        .background(SBColor.background.ignoresSafeArea())
        .navigationTitle("Bookings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedBooking) { row in
            AdminCourtBookingDetailSheet(
                row: row,
                onCancel: {
                    selectedBooking = nil
                    pendingCancel = row
                }
            )
            .themeManager(themeManager)
        }
        .alert(
            "Cancel booking?",
            isPresented: Binding(
                get: { pendingCancel != nil },
                set: { if !$0 { pendingCancel = nil } }
            )
        ) {
            Button("Keep", role: .cancel) { pendingCancel = nil }
            Button("Cancel booking", role: .destructive) {
                if let row = pendingCancel {
                    _ = viewModel.cancelCourtBooking(id: row.id)
                }
                pendingCancel = nil
            }
        } message: {
            if let row = pendingCancel {
                Text(
                    "\(row.customerName) on Court \(row.courtNumber) · \(row.dateTimeLabel()) "
                        + "(\(row.referenceCode)) will be cancelled."
                )
            }
        }
    }

    private var segmentBinding: Binding<BookingsSegment> {
        Binding(
            get: { viewModel.bookingsSegment },
            set: { viewModel.selectBookingsSegment($0) }
        )
    }

    private var upcomingCount: Int {
        viewModel.allAdminBookings.filter { $0.status == .confirmed && $0.end > Date() }.count
    }

    private var pastCount: Int {
        viewModel.allAdminBookings.filter { $0.status != .confirmed || $0.end <= Date() }.count
    }
}

// MARK: - Detail sheet

struct AdminCourtBookingDetailSheet: View {
    let row: AdminCourtBookingRow
    var onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    HStack {
                        BookingStatusBadge(status: displayStatus)
                        Spacer()
                        if row.isGuest {
                            Text("Guest")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(themeManager.primary(for: colorScheme))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill(themeManager.primaryMuted(for: colorScheme))
                                )
                        }
                    }

                    CardView(showsShadow: false, showsBorder: true) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            rowItem("Customer", row.customerName)
                            Divider().overlay(SBColor.border)
                            rowItem("Phone", row.customerPhone)
                            Divider().overlay(SBColor.border)
                            rowItem("Club", row.clubName)
                            Divider().overlay(SBColor.border)
                            rowItem("Court", "Court \(row.courtNumber)")
                        }
                    }

                    CardView(showsShadow: false, showsBorder: true) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            rowItem("When", row.dateTimeLabel())
                            Divider().overlay(SBColor.border)
                            rowItem("Duration", row.durationLabel)
                            Divider().overlay(SBColor.border)
                            rowItem("Reference", row.referenceCode)
                        }
                    }

                    if row.status == .confirmed && row.end > Date() {
                        PrimaryButton(title: "Cancel booking") {
                            onCancel()
                        }
                        Text("Cancelling frees this court for new customers.")
                            .sbFontCaption()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .background(SBColor.background.ignoresSafeArea())
            .navigationTitle("Booking detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(themeManager.primary(for: colorScheme))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var displayStatus: BookingDisplayStatus {
        switch row.status {
        case .cancelled: return .cancelled
        case .confirmed: return row.end > Date() ? .upcoming : .completed
        }
    }

    private func rowItem(_ title: String, _ value: String) -> some View {
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

#Preview("Admin bookings") {
    let store = BookingStore()
    store.seedCourtPreviewData()
    let vm = AdminStoreViewModel()
    vm.attach(store: store)

    return NavigationStack {
        AdminBookingsListView(viewModel: vm)
            .task { await vm.load() }
    }
    .bookingStore(store)
    .themeManager(ThemeManager())
    .repositories(.makeDefault())
}
