//
//  CourtBookingReviewSheet.swift
//  SlotBook
//
//  Intermediate booking sheet: confirms date, time, duration (no courts shown).
//  Guest details form arrives in Iteration 4.
//

import SwiftUI

struct CourtBookingReviewSheet: View {
    let draft: CourtBookingDraft
    let onContinue: () -> Void
    let onDismiss: () -> Void

    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    private var accent: Color {
        draft.club.primaryColor.swiftUIColor
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    header
                    summaryCard
                    noteCard
                    PrimaryButton(title: "Continue to Booking Details") {
                        onContinue()
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .background(SBColor.background.ignoresSafeArea())
            .navigationTitle("Review time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { onDismiss() }
                        .foregroundStyle(themeManager.primary(for: colorScheme))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(draft.club.name)
                .sbFontHeadline()
            Text("You’re booking a court — we’ll assign one automatically.")
                .sbFontCaption()
        }
        .accessibilityElement(children: .combine)
    }

    private var summaryCard: some View {
        CardView(showsShadow: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                summaryRow(
                    icon: "calendar",
                    title: "Date",
                    value: dateLabel
                )
                Divider().opacity(0.5)
                summaryRow(
                    icon: "clock",
                    title: "Time",
                    value: draft.option.rangeLabel()
                )
                Divider().opacity(0.5)
                summaryRow(
                    icon: "hourglass",
                    title: "Duration",
                    value: "\(draft.durationMinutes) minutes"
                )
                Divider().opacity(0.5)
                summaryRow(
                    icon: "dollarsign.circle",
                    title: "Estimated",
                    value: draft.estimatedPriceLabel
                )
            }
        }
    }

    private var noteCard: some View {
        CardView(showsShadow: false, showsBorder: true) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(accent)
                    .font(.system(size: 18))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Court assigned for you")
                        .font(.system(.subheadline, design: .default).weight(.semibold))
                        .foregroundStyle(SBColor.textPrimary)
                    Text("You won’t pick a court number — SlotBook holds the next free court for this time.")
                        .sbFontCaption()
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func summaryRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 22)
            Text(title)
                .sbFontCaption()
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .default).weight(.semibold))
                .foregroundStyle(SBColor.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: draft.date)
    }
}

// MARK: - Previews

#Preview("Review sheet") {
    let day = Calendar.current.startOfDay(for: Date().addingTimeInterval(86_400))
    let options = MockData.findAvailableSlots(
        clubId: MockData.torontoClubId,
        date: day,
        durationMinutes: 60
    )
    let option = options.first(where: \.isAvailable)!
    let draft = CourtBookingDraft(club: MockData.clubs[0], option: option, date: day)

    return CourtBookingReviewSheet(
        draft: draft,
        onContinue: {},
        onDismiss: {}
    )
    .themeManager(ThemeManager())
}
