//
//  AdminBookingDetailSheet.swift
//  SlotBook
//
//  Owner booking detail: customer info, time, status, cancel.
//

import SwiftUI

struct AdminBookingDetailSheet: View {
    let booking: AdminBooking
    var onCancel: () -> Void

    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var confirmCancel = false

    private let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .short
        return f
    }()

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    statusBadge

                    CardView(showsShadow: false, showsBorder: true) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            row("Customer", booking.customerName)
                            Divider().overlay(SBColor.border)
                            row("Phone", booking.customerPhone)
                            if let email = booking.customerEmail {
                                Divider().overlay(SBColor.border)
                                row("Email", email)
                            }
                            Divider().overlay(SBColor.border)
                            row("Type", booking.isGuest ? "Guest" : "Account")
                        }
                    }

                    CardView(showsShadow: false, showsBorder: true) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            row("Service", booking.serviceName)
                            Divider().overlay(SBColor.border)
                            row("When", dateTimeFormatter.string(from: booking.start))
                            Divider().overlay(SBColor.border)
                            row(
                                "Time",
                                "\(timeFormatter.string(from: booking.start)) – \(timeFormatter.string(from: booking.end))"
                            )
                            Divider().overlay(SBColor.border)
                            row("Reference", booking.referenceCode)
                        }
                    }

                    if booking.status == .confirmed {
                        PrimaryButton(title: "Cancel booking") {
                            confirmCancel = true
                        }
                        Text("Cancelling frees the slot for new customers.")
                            .sbFontCaption()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .background(SBColor.background.ignoresSafeArea())
            .navigationTitle("Booking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(themeManager.preset.primary(for: colorScheme))
                }
            }
            .confirmationDialog(
                "Cancel this booking?",
                isPresented: $confirmCancel,
                titleVisibility: .visible
            ) {
                Button("Cancel booking", role: .destructive) {
                    onCancel()
                    dismiss()
                }
                Button("Keep booking", role: .cancel) {}
            } message: {
                Text("\(booking.customerName) · \(booking.customerPhone) will be released.")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var statusBadge: some View {
        Text(booking.status.displayName)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(themeManager.preset.primary(for: colorScheme))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(themeManager.preset.primaryMuted(for: colorScheme))
            )
    }

    private func row(_ title: String, _ value: String) -> some View {
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

#Preview {
    AdminBookingDetailSheet(
        booking: AdminBooking(
            id: UUID(),
            serviceId: UUID(),
            serviceName: "Morning Flow Yoga",
            customerName: "Maya Torres",
            customerPhone: "(555) 201-8844",
            customerEmail: nil,
            start: Date(),
            end: Date().addingTimeInterval(1800),
            status: .confirmed,
            referenceCode: "SB-A1B2",
            isGuest: true
        ),
        onCancel: {}
    )
    .themeManager(ThemeManager())
}
