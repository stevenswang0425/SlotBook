//
//  AdminItemCalendarView.swift
//  SlotBook
//
//  Week calendar for one service: available vs booked slots + day totals.
//

import SwiftUI

struct AdminItemCalendarView: View {
    let service: AdminService
    @Bindable var viewModel: MarketplaceAdminStoreViewModel

    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedDay: Date = Date()
    @State private var selectedBooking: AdminBooking?

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEE d")
        return f
    }()

    var body: some View {
        ZStack {
            SBColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                weekChrome
                dayStrip
                daySummary
                slotList
            }
        }
        .navigationTitle(service.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedBooking) { booking in
            AdminBookingDetailSheet(booking: booking) {
                viewModel.cancelBooking(booking)
                selectedBooking = nil
            }
        }
        .onAppear {
            if let first = viewModel.daysInWeek().first {
                selectedDay = first
            }
        }
    }

    // MARK: - Week controls

    private var weekChrome: some View {
        HStack {
            Button {
                viewModel.goToPreviousWeek()
                snapSelectedDayIntoWeek()
                HapticFeedback.selection()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themeManager.preset.primary(for: colorScheme))
                    .frame(width: 40, height: 40)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(viewModel.weekRangeLabel)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SBColor.textPrimary)
                Button("This week") {
                    viewModel.goToThisWeek()
                    snapSelectedDayIntoWeek()
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(themeManager.preset.primary(for: colorScheme))
            }

            Spacer()

            Button {
                viewModel.goToNextWeek()
                snapSelectedDayIntoWeek()
                HapticFeedback.selection()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themeManager.preset.primary(for: colorScheme))
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Day strip

    private var dayStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(viewModel.daysInWeek(), id: \.self) { day in
                    let selected = Calendar.current.isDate(day, inSameDayAs: selectedDay)
                    let count = viewModel.bookingCount(for: service.id, on: day)
                    Button {
                        selectedDay = day
                        HapticFeedback.selection()
                    } label: {
                        VStack(spacing: 4) {
                            Text(dayFormatter.string(from: day))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(selected ? Color.white : SBColor.textPrimary)
                            Text("\(count)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(selected ? Color.white.opacity(0.9) : themeManager.preset.primary(for: colorScheme))
                            Text("booked")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(selected ? Color.white.opacity(0.75) : SBColor.textTertiary)
                        }
                        .frame(width: 72)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                .fill(selected ? themeManager.preset.primary(for: colorScheme) : SBColor.card)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                .stroke(selected ? Color.clear : SBColor.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(SBPressableButtonStyle())
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.sm)
        }
    }

    private var daySummary: some View {
        let daySlots = viewModel.slots(for: service.id, on: selectedDay)
        let booked = daySlots.filter(\.isBooked).count
        let free = daySlots.filter(\.isAvailable).count

        return HStack(spacing: Spacing.md) {
            legendDot(color: themeManager.preset.primary(for: colorScheme), label: "\(booked) booked")
            legendDot(color: SBColor.chipBackground, border: SBColor.border, label: "\(free) open")
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.sm)
    }

    private func legendDot(color: Color, border: Color? = nil, label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(color)
                .overlay {
                    if let border {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(border, lineWidth: 1)
                    }
                }
                .frame(width: 12, height: 12)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SBColor.textSecondary)
        }
    }

    // MARK: - Slot list

    private var slotList: some View {
        let daySlots = viewModel.slots(for: service.id, on: selectedDay)

        return ScrollView {
            LazyVStack(spacing: Spacing.xs) {
                if daySlots.isEmpty {
                    Text("No slots for this day.")
                        .sbFontCaption()
                        .frame(maxWidth: .infinity)
                        .padding(.top, Spacing.xxl)
                } else {
                    ForEach(daySlots) { slot in
                        slotRow(slot)
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxxl)
        }
    }

    @ViewBuilder
    private func slotRow(_ slot: AdminSlotOccurrence) -> some View {
        let primary = themeManager.preset.primary(for: colorScheme)
        let booked = slot.isBooked

        Button {
            if let booking = slot.booking, booking.status == .confirmed {
                selectedBooking = booking
            }
        } label: {
            HStack(spacing: Spacing.md) {
                Text(timeFormatter.string(from: slot.start))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(booked ? Color.white : SBColor.textPrimary)
                    .frame(width: 72, alignment: .leading)

                if let booking = slot.booking, booking.status == .confirmed {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(booking.customerName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(booking.customerPhone)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                } else {
                    Text("Available")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(SBColor.textSecondary)
                }

                Spacer()

                if booked {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(booked ? primary : SBColor.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(booked ? Color.clear : SBColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(SBPressableButtonStyle())
        .disabled(!booked)
        .accessibilityLabel(slotAccessibility(slot))
    }

    private func slotAccessibility(_ slot: AdminSlotOccurrence) -> String {
        let time = timeFormatter.string(from: slot.start)
        if let b = slot.booking, b.status == .confirmed {
            return "\(time), booked by \(b.customerName), \(b.customerPhone)"
        }
        return "\(time), available"
    }

    private func snapSelectedDayIntoWeek() {
        let days = viewModel.daysInWeek()
        if !days.contains(where: { Calendar.current.isDate($0, inSameDayAs: selectedDay) }) {
            selectedDay = days.first ?? selectedDay
        }
    }
}

// MARK: - Previews

#Preview("Calendar") {
    let vm = MarketplaceAdminStoreViewModel()
    vm.load()
    return NavigationStack {
        AdminItemCalendarView(service: MockAdminData.services[1], viewModel: vm)
    }
    .themeManager(ThemeManager())
}
