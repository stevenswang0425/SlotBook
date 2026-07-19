//
//  AdminStoreView.swift
//  SlotBook
//
//  Owner “My Store” hub — list of services + entry to calendars.
//

import SwiftUI

struct AdminStoreView: View {
    @Environment(\.userSession) private var userSession
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel = AdminStoreViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                SBColor.background.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                        .tint(themeManager.preset.primary(for: colorScheme))
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.lg) {
                            storeHeader
                            servicesList
                        }
                        .padding(.horizontal, Spacing.xl)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.xxxl)
                    }
                }
            }
            .navigationTitle("My Store")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { viewModel.load() }
        }
    }

    // MARK: - Header

    private var storeHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Text("Admin Mode")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(themeManager.preset.primary(for: colorScheme))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(themeManager.preset.primaryMuted(for: colorScheme))
                    )
                Spacer()
            }

            Text(userSession.currentUser?.storeName ?? userSession.displayName)
                .sbFontTitle()

            if let desc = userSession.currentUser?.storeDescription, !desc.isEmpty {
                Text(desc)
                    .sbFontBody()
            } else {
                Text("Manage services and see who’s booked this week.")
                    .sbFontBody()
            }
        }
    }

    // MARK: - Services

    private var servicesList: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Services")
                .sbFontHeadline()

            if viewModel.services.isEmpty {
                EmptyStateView(
                    systemImage: "tray",
                    title: "No services yet",
                    message: "Your store catalog will appear here."
                )
            } else {
                ForEach(viewModel.services) { service in
                    NavigationLink {
                        AdminItemCalendarView(service: service, viewModel: viewModel)
                    } label: {
                        serviceRow(service)
                    }
                    .buttonStyle(SBPressableButtonStyle())
                }
            }
        }
    }

    private func serviceRow(_ service: AdminService) -> some View {
        CardView(showsShadow: true, showsBorder: false) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    service.color.swiftUIColor.opacity(0.9),
                                    service.color.swiftUIColor.opacity(0.5),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: service.imageName)
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .sbFontSubheadline()
                        .foregroundStyle(SBColor.textPrimary)

                    Text("\(service.durationMinutes) min · \(service.category.displayName)")
                        .sbFontCaption()

                    Text("\(viewModel.weekBookingCount(for: service.id)) bookings this week")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(themeManager.preset.primary(for: colorScheme))
                }

                Spacer(minLength: 0)

                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SBColor.textTertiary)
            }
        }
    }
}

// MARK: - Previews

#Preview("Admin Store") {
    let session = UserSession()
    session.becomeStoreOwner(
        StoreOwnerSignup(
            storeName: "Harbor Collective",
            phone: "(555) 010-2000",
            email: nil,
            serviceDescription: "Cafe & wellness"
        )
    )
    return AdminStoreView()
        .themeManager(ThemeManager())
        .userSession(session)
}
