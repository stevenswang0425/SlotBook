//
//  AdminClubDetailView.swift
//  SlotBook
//
//  Club management: edit info, courts (numbers visible), today's bookings.
//

import SwiftUI

struct AdminClubDetailView: View {
    let clubId: UUID
    var adminRepository: any AdminClubRepository = MockAdminClubRepository.shared

    @Environment(\.bookingStore) private var bookingStore
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel: AdminClubDetailViewModel?
    @State private var courtToRemove: AdminManagedCourt?
    @State private var bookingToCancel: AdminCourtBookingRow?
    @State private var selectedCourtFilter: UUID?

    private var accent: Color {
        viewModel?.primaryColor.swiftUIColor ?? themeManager.primary(for: colorScheme)
    }

    var body: some View {
        ZStack {
            SBColor.background.ignoresSafeArea()

            if let viewModel {
                detailBody(viewModel)
            } else {
                ProgressView()
                    .tint(themeManager.primary(for: colorScheme))
            }
        }
        .navigationTitle(viewModel?.clubName ?? "Club")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let viewModel {
                    Button {
                        Task { await viewModel.saveClub() }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
        }
        .task {
            if viewModel == nil {
                let vm = AdminClubDetailViewModel(
                    clubId: clubId,
                    adminRepository: adminRepository
                )
                vm.attach(store: bookingStore)
                viewModel = vm
            }
            await viewModel?.load()
            if let club = viewModel {
                // Soft brand for admin detail
                themeManager.clubPrimaryOverride = club.primaryColor.swiftUIColor
            }
        }
        .onDisappear {
            themeManager.clearClubTheme()
        }
        .alert(
            "Remove court?",
            isPresented: Binding(
                get: { courtToRemove != nil },
                set: { if !$0 { courtToRemove = nil } }
            )
        ) {
            Button("Keep court", role: .cancel) { courtToRemove = nil }
            Button("Remove", role: .destructive) {
                if let court = courtToRemove, let viewModel {
                    Task { await viewModel.removeCourt(court) }
                }
                courtToRemove = nil
            }
        } message: {
            if let court = courtToRemove {
                Text("Court \(court.courtNumber) will be removed from inventory. Customers never see court numbers.")
            }
        }
        .alert(
            "Cancel booking?",
            isPresented: Binding(
                get: { bookingToCancel != nil },
                set: { if !$0 { bookingToCancel = nil } }
            )
        ) {
            Button("Keep", role: .cancel) { bookingToCancel = nil }
            Button("Cancel booking", role: .destructive) {
                if let row = bookingToCancel {
                    _ = viewModel?.cancelBooking(id: row.id)
                }
                bookingToCancel = nil
            }
        } message: {
            if let row = bookingToCancel {
                Text("\(row.customerName) · Court \(row.courtNumber) · \(row.dateTimeLabel()) will be cancelled.")
            }
        }
    }

    // MARK: - Body

    @ViewBuilder
    private func detailBody(_ viewModel: AdminClubDetailViewModel) -> some View {
        let _ = bookingStore.reservationEpoch

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, Spacing.xxl)
                } else {
                    clubInfoSection(viewModel)
                    courtsSection(viewModel)
                    todayBookingsSection(viewModel)
                    weekBookingsSection(viewModel)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SBColor.destructive)
                        .padding(.horizontal, Spacing.xl)
                }
            }
            .padding(.bottom, Spacing.xxxl)
        }
        .overlay(alignment: .bottom) {
            if viewModel.showToast, let message = viewModel.toastMessage {
                ToastBanner(message: message, style: .success)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.xl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task(id: message) {
                        try? await Task.sleep(for: .seconds(2.2))
                        viewModel.dismissToast()
                    }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: viewModel.showToast)
    }

    // MARK: - Club info

    private func clubInfoSection(_ viewModel: AdminClubDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionTitle("Club info")

            CardView(showsShadow: false, showsBorder: true) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    adminField("Name", text: binding(\.name, on: viewModel))
                    adminField("Description", text: binding(\.descriptionText, on: viewModel), axis: .vertical)
                    adminField("Address", text: binding(\.address, on: viewModel))
                    adminField("City", text: binding(\.city, on: viewModel))
                    adminField("Opening hours", text: binding(\.openingHours, on: viewModel))

                    HStack {
                        Text("Price / hour")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(SBColor.textSecondary)
                        Spacer()
                        Stepper(
                            "\(viewModel.pricePerHourCAD)",
                            value: Binding(
                                get: { viewModel.pricePerHourCAD },
                                set: { viewModel.pricePerHourCAD = $0 }
                            ),
                            in: 10...80
                        )
                        .labelsHidden()
                        Text("$\(viewModel.pricePerHourCAD)")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                    }

                    Toggle("Indoor", isOn: Binding(
                        get: { viewModel.isIndoor },
                        set: { viewModel.isIndoor = $0 }
                    ))
                    Toggle("Coaching offered", isOn: Binding(
                        get: { viewModel.hasCoaching },
                        set: { viewModel.hasCoaching = $0 }
                    ))

                    // Primary color swatches
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Primary color")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(SBColor.textSecondary)
                        HStack(spacing: Spacing.sm) {
                            ForEach(Self.colorPresets, id: \.r) { color in
                                let selected = viewModel.primaryColor.red == Double(color.r) / 255
                                    && viewModel.primaryColor.green == Double(color.g) / 255
                                Button {
                                    viewModel.primaryColor = ItemColor(r: color.r, g: color.g, b: color.b)
                                    HapticFeedback.selection()
                                } label: {
                                    Circle()
                                        .fill(Color(red: Double(color.r) / 255, green: Double(color.g) / 255, blue: Double(color.b) / 255))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selected ? 3 : 0)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(SBColor.border, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Color preset")
                                .accessibilityAddTraits(selected ? .isSelected : [])
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)
        }
    }

    // MARK: - Courts

    private func courtsSection(_ viewModel: AdminClubDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                sectionTitle("Courts")
                Spacer()
                Text("\(viewModel.activeCourtCount) active")
                    .sbFontCaption()
                    .padding(.trailing, Spacing.xl)
            }

            Text("Court numbers are admin-only. Customers never see these.")
                .sbFontCaption()
                .padding(.horizontal, Spacing.xl)

            ForEach(viewModel.courts) { court in
                courtRow(court, viewModel: viewModel)
                    .padding(.horizontal, Spacing.xl)
            }

            Button {
                Task { await viewModel.addCourt() }
            } label: {
                Label("Add court", systemImage: "plus.circle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.xs)
            }
            .buttonStyle(SBPressableButtonStyle())
        }
    }

    private func courtRow(_ court: AdminManagedCourt, viewModel: AdminClubDetailViewModel) -> some View {
        let upcoming = viewModel.bookings(forCourt: court.id)

        return CardView(padding: Spacing.md, cornerRadius: Radius.md, showsShadow: false, showsBorder: true) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(court.displayName)
                            .font(.system(.subheadline, design: .default).weight(.semibold))
                            .foregroundStyle(SBColor.textPrimary)
                        Text(court.isActive ? "Active inventory" : "Inactive — not bookable")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(court.isActive ? SBColor.success : SBColor.textTertiary)
                    }
                    Spacer()
                    Toggle(
                        "",
                        isOn: Binding(
                            get: { court.isActive },
                            set: { _ in Task { await viewModel.toggleCourtActive(court) } }
                        )
                    )
                    .labelsHidden()
                    .tint(accent)
                }

                if !upcoming.isEmpty {
                    Divider().overlay(SBColor.border)
                    Text("Upcoming on this court")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SBColor.textSecondary)
                    ForEach(upcoming.prefix(3)) { row in
                        HStack {
                            Text(row.customerName)
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            Text(row.rangeLabel())
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(SBColor.textSecondary)
                        }
                    }
                }

                Button(role: .destructive) {
                    courtToRemove = court
                } label: {
                    Text("Remove court")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SBColor.destructive)
                }
                .buttonStyle(SBPressableButtonStyle())
            }
        }
    }

    // MARK: - Bookings

    private func todayBookingsSection(_ viewModel: AdminClubDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionTitle("Today’s bookings")

            let rows = viewModel.todayBookings
            if rows.isEmpty {
                CardView(showsShadow: false, showsBorder: true) {
                    Text("No bookings scheduled for today.")
                        .sbFontCaption()
                }
                .padding(.horizontal, Spacing.xl)
            } else {
                ForEach(rows) { row in
                    adminBookingCard(row)
                        .padding(.horizontal, Spacing.xl)
                }
            }
        }
    }

    private func weekBookingsSection(_ viewModel: AdminClubDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionTitle("This week")

            let rows = viewModel.weekBookings
            if rows.isEmpty {
                CardView(showsShadow: false, showsBorder: true) {
                    Text("No bookings this week yet.")
                        .sbFontCaption()
                }
                .padding(.horizontal, Spacing.xl)
            } else {
                ForEach(rows.prefix(12)) { row in
                    adminBookingCard(row)
                        .padding(.horizontal, Spacing.xl)
                }
            }
        }
    }

    private func adminBookingCard(_ row: AdminCourtBookingRow) -> some View {
        CardView(padding: Spacing.md, cornerRadius: Radius.md, showsShadow: false, showsBorder: true) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(row.customerName)
                        .font(.system(.subheadline, design: .default).weight(.semibold))
                    Spacer()
                    Text("Court \(row.courtNumber)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(accent.opacity(0.12)))
                }
                Text(row.dateTimeLabel())
                    .sbFontCaption()
                HStack {
                    Text(row.customerPhone)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SBColor.textSecondary)
                    Text("·")
                    Text(row.referenceCode)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(SBColor.textTertiary)
                    Spacer()
                    if row.status == .confirmed && row.end > Date() {
                        Button("Cancel") {
                            bookingToCancel = row
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SBColor.destructive)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .sbFontHeadline()
            .padding(.horizontal, Spacing.xl)
    }

    private func adminField(
        _ title: String,
        text: Binding<String>,
        axis: Axis = .horizontal
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SBColor.textSecondary)
            if axis == .vertical {
                TextField(title, text: text, axis: .vertical)
                    .lineLimit(3...6)
                    .font(.system(size: 16))
                    .padding(Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                            .fill(SBColor.chipBackground)
                    )
            } else {
                TextField(title, text: text)
                    .font(.system(size: 16))
                    .padding(Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                            .fill(SBColor.chipBackground)
                    )
            }
        }
    }

    private func binding(
        _ keyPath: ReferenceWritableKeyPath<AdminClubDetailViewModel, String>,
        on viewModel: AdminClubDetailViewModel
    ) -> Binding<String> {
        Binding(
            get: { viewModel[keyPath: keyPath] },
            set: { viewModel[keyPath: keyPath] = $0 }
        )
    }

    private static let colorPresets: [(r: Int, g: Int, b: Int)] = [
        (37, 99, 235),
        (22, 163, 74),
        (124, 58, 237),
        (234, 88, 12),
        (8, 145, 178),
    ]
}

// MARK: - Previews

#Preview("Admin Club Detail") {
    let store = BookingStore()
    store.seedCourtPreviewData()

    return NavigationStack {
        AdminClubDetailView(clubId: MockData.torontoClubId)
    }
    .bookingStore(store)
    .themeManager(ThemeManager())
    .repositories(.makeDefault())
}
