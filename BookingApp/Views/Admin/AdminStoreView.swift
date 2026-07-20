//
//  AdminStoreView.swift
//  SlotBook
//
//  Owner “My Store” hub — managed badminton clubs, utilization, bookings entry.
//

import SwiftUI

struct AdminStoreView: View {
    @Environment(\.userSession) private var userSession
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.bookingStore) private var bookingStore
    @Environment(\.repositories) private var repositories

    @State private var viewModel: AdminStoreViewModel?

    var body: some View {
        NavigationStack {
            ZStack {
                SBColor.background.ignoresSafeArea()

                if let viewModel {
                    content(viewModel)
                } else {
                    ProgressView()
                        .tint(themeManager.primary(for: colorScheme))
                }
            }
            .navigationTitle("My Store")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let viewModel {
                        NavigationLink {
                            AdminBookingsListView(viewModel: viewModel)
                        } label: {
                            Image(systemName: "list.clipboard")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .accessibilityLabel("All bookings")
                    }
                }
            }
            .task {
                if viewModel == nil {
                    let vm = AdminStoreViewModel(adminRepository: repositories.adminClubs)
                    vm.attach(store: bookingStore)
                    viewModel = vm
                }
                await viewModel?.load()
            }
            .refreshable {
                await viewModel?.refresh()
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ viewModel: AdminStoreViewModel) -> some View {
        let _ = bookingStore.reservationEpoch
        let _ = bookingStore.courtBookings

        if viewModel.isLoading && viewModel.clubs.isEmpty {
            ProgressView()
                .tint(themeManager.primary(for: colorScheme))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.loadError, viewModel.clubs.isEmpty {
            EmptyStateView(
                systemImage: "wifi.exclamationmark",
                title: "Couldn't load clubs",
                message: error,
                actionTitle: "Try again",
                action: { Task { await viewModel.load() } }
            )
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    storeHeader
                    quickStats(viewModel)
                    clubsSection(viewModel)
                    bookingsTeaser(viewModel)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxxl)
            }
        }
    }

    // MARK: - Header

    private var storeHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Text("Admin Mode")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(themeManager.primary(for: colorScheme))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(themeManager.primaryMuted(for: colorScheme))
                    )
                Spacer()
            }

            Text(userSession.currentUser?.storeName ?? userSession.displayName)
                .sbFontTitle()

            if let desc = userSession.currentUser?.storeDescription, !desc.isEmpty {
                Text(desc)
                    .sbFontBody()
            } else {
                Text("Manage badminton clubs, courts, and bookings.")
                    .sbFontBody()
            }
        }
    }

    // MARK: - Stats

    private func quickStats(_ viewModel: AdminStoreViewModel) -> some View {
        let totalCourts = viewModel.clubs.reduce(0) { $0 + viewModel.totalCourtCount(for: $1.id) }
        let todayBookings = viewModel.clubs.reduce(0) {
            $0 + viewModel.utilization(for: $1.id).todayBookingCount
        }

        return HStack(spacing: Spacing.sm) {
            statChip(title: "Clubs", value: "\(viewModel.clubs.count)")
            statChip(title: "Courts", value: "\(totalCourts)")
            statChip(title: "Today", value: "\(todayBookings)")
        }
    }

    private func statChip(title: String, value: String) -> some View {
        CardView(padding: Spacing.sm, cornerRadius: Radius.md, showsShadow: false, showsBorder: true) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SBColor.textSecondary)
                Text(value)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(SBColor.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Clubs

    private func clubsSection(_ viewModel: AdminStoreViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Clubs")
                .sbFontHeadline()

            if viewModel.clubs.isEmpty {
                EmptyStateView(
                    systemImage: "building.2",
                    title: "No clubs yet",
                    message: "Managed badminton clubs will appear here."
                )
            } else {
                ForEach(viewModel.clubs) { club in
                    NavigationLink {
                        AdminClubDetailView(
                            clubId: club.id,
                            adminRepository: repositories.adminClubs
                        )
                    } label: {
                        AdminClubRowCard(
                            club: club,
                            courtCount: viewModel.totalCourtCount(for: club.id),
                            activeCourts: viewModel.activeCourtCount(for: club.id),
                            utilization: viewModel.utilization(for: club.id)
                        )
                    }
                    .buttonStyle(SBPressableButtonStyle())
                }
            }
        }
    }

    // MARK: - Bookings teaser

    private func bookingsTeaser(_ viewModel: AdminStoreViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Bookings")
                    .sbFontHeadline()
                Spacer()
                NavigationLink {
                    AdminBookingsListView(viewModel: viewModel)
                } label: {
                    Text("See all")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(themeManager.primary(for: colorScheme))
                }
            }

            let upcoming = viewModel.displayedAdminBookings.prefix(3)
            if upcoming.isEmpty {
                CardView(showsShadow: false, showsBorder: true) {
                    Text("No upcoming bookings across your clubs.")
                        .sbFontCaption()
                }
            } else {
                ForEach(Array(upcoming)) { row in
                    AdminBookingRowCard(row: row, showsCourt: true)
                }
            }
        }
    }
}

// MARK: - Club row

struct AdminClubRowCard: View {
    let club: AdminManagedClub
    let courtCount: Int
    let activeCourts: Int
    let utilization: ClubUtilization

    private var accent: Color { club.primaryColor.swiftUIColor }

    var body: some View {
        CardView(showsShadow: true) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [accent.opacity(0.92), accent.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)
                        Image(systemName: club.imageName)
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(club.name)
                            .sbFontSubheadline()
                            .foregroundStyle(SBColor.textPrimary)
                            .lineLimit(2)
                        Text(club.locationLabel)
                            .sbFontCaption()
                            .lineLimit(1)
                        Text("\(courtCount) courts · \(activeCourts) active")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(SBColor.textTertiary)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SBColor.textTertiary)
                }

                // Utilization
                HStack(spacing: Spacing.md) {
                    utilizationMeter(
                        title: "Today",
                        percent: utilization.todayPercentLabel,
                        fraction: utilization.today,
                        subtitle: "\(utilization.todayBookingCount) bookings"
                    )
                    utilizationMeter(
                        title: "This week",
                        percent: utilization.weekPercentLabel,
                        fraction: utilization.week,
                        subtitle: "\(utilization.weekBookingCount) bookings"
                    )
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(club.name), \(courtCount) courts, today \(utilization.todayPercentLabel) utilized"
        )
        .accessibilityHint("Opens club management")
    }

    private func utilizationMeter(
        title: String,
        percent: String,
        fraction: Double,
        subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SBColor.textSecondary)
                Spacer()
                Text(percent)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(SBColor.chipBackground)
                    Capsule()
                        .fill(accent.opacity(0.85))
                        .frame(width: max(4, geo.size.width * fraction))
                }
            }
            .frame(height: 6)
            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(SBColor.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Booking row (admin)

struct AdminBookingRowCard: View {
    let row: AdminCourtBookingRow
    var showsCourt: Bool = true

    var body: some View {
        CardView(padding: Spacing.md, cornerRadius: Radius.md, showsShadow: false, showsBorder: true) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(row.customerName)
                        .font(.system(.subheadline, design: .default).weight(.semibold))
                        .foregroundStyle(SBColor.textPrimary)
                    Spacer()
                    statusPill
                }
                Text(row.clubName)
                    .sbFontCaption()
                Text(row.dateTimeLabel())
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SBColor.textSecondary)
                HStack(spacing: Spacing.xs) {
                    if showsCourt {
                        Text("Court \(row.courtNumber)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SBColor.textPrimary)
                        Text("·")
                            .foregroundStyle(SBColor.textTertiary)
                    }
                    Text(row.durationLabel)
                    Text("·")
                        .foregroundStyle(SBColor.textTertiary)
                    Text(row.referenceCode)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SBColor.textTertiary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var statusPill: some View {
        let display: BookingDisplayStatus = {
            switch row.status {
            case .cancelled: return .cancelled
            case .confirmed: return row.end > Date() ? .upcoming : .completed
            }
        }()
        return BookingStatusBadge(status: display)
    }
}

// MARK: - Previews

#Preview("Admin Store — Owner") {
    let session = UserSession()
    session.becomeStoreOwner(
        StoreOwnerSignup(
            storeName: "GTA Badminton Group",
            phone: "(555) 010-2000",
            email: nil,
            serviceDescription: "Multi-club operator"
        )
    )
    let store = BookingStore()
    store.seedCourtPreviewData()

    return AdminStoreView()
        .themeManager(ThemeManager())
        .userSession(session)
        .bookingStore(store)
        .repositories(.makeDefault())
}
