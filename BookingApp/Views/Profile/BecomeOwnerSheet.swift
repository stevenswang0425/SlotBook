//
//  BecomeOwnerSheet.swift
//  SlotBook
//
//  Hidden store-owner onboarding (triggered by secret avatar gesture).
//

import SwiftUI

struct BecomeOwnerSheet: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.userSession) private var userSession
    @Environment(\.appNavigation) private var appNavigation

    @State private var storeName = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var serviceDescription = ""

    @State private var storeNameError: String?
    @State private var phoneError: String?
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    headerCopy
                    formFields
                    PrimaryButton(
                        title: "Create My Store",
                        isLoading: isSubmitting,
                        action: submit
                    )
                    .padding(.top, Spacing.xs)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .background(SBColor.background.ignoresSafeArea())
            .navigationTitle("Become a Store Owner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(themeManager.preset.primary(for: colorScheme))
                        .disabled(isSubmitting)
                }
            }
            .interactiveDismissDisabled(isSubmitting)
            .scrollDismissesKeyboard(.interactively)
            .alert("Welcome!", isPresented: $showSuccessAlert) {
                Button("Open My Store") {
                    dismiss()
                    appNavigation.openAdmin()
                }
                Button("Later", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Welcome! Your store has been created. Manage services and bookings in My Store.")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    private var headerCopy: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Are you a business owner?")
                .sbFontHeadline()
            Text("Create your store on SlotBook")
                .sbFontBody()
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var formFields: some View {
        VStack(spacing: Spacing.md) {
            SBTextField(
                title: "Business / Store Name",
                placeholder: "e.g. Harbor Collective",
                text: $storeName,
                textContentType: .organizationName,
                error: storeNameError
            )
            .onChange(of: storeName) { _, _ in storeNameError = nil }

            SBTextField(
                title: "Phone Number",
                placeholder: "(555) 123-4567",
                text: $phone,
                keyboardType: .phonePad,
                textContentType: .telephoneNumber,
                error: phoneError,
                autocapitalization: .never
            )
            .onChange(of: phone) { _, newValue in
                phone = formatPhoneMask(newValue)
                phoneError = nil
            }

            SBTextField(
                title: "Email (optional)",
                placeholder: "you@business.com",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                autocapitalization: .never
            )

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Brief description of your service")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SBColor.textSecondary)

                TextField(
                    "What do you offer?",
                    text: $serviceDescription,
                    axis: .vertical
                )
                .lineLimit(3...6)
                .font(.system(size: 16, weight: .regular))
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm + 2)
                .background(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .fill(SBColor.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .stroke(SBColor.border, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Submit

    private func submit() {
        let trimmedName = storeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = phone.filter(\.isNumber)

        storeNameError = trimmedName.count >= 2 ? nil : "Store name is required"
        phoneError = digits.count >= 10 ? nil : "Enter a valid phone number"

        guard storeNameError == nil, phoneError == nil else {
            HapticFeedback.warning()
            return
        }

        isSubmitting = true

        Task {
            // Simulated network create.
            try? await Task.sleep(for: .milliseconds(800))

            let signup = StoreOwnerSignup(
                storeName: trimmedName,
                phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                serviceDescription: serviceDescription
            )

            userSession.becomeStoreOwner(signup)

            // Soft brand shift for owners (wellness-friendly Forest).
            withAnimation(.easeInOut(duration: 0.35)) {
                themeManager.apply(.forest)
            }

            isSubmitting = false
            showSuccessAlert = true
        }
    }

    /// North-American style mask (shared feel with booking form).
    private func formatPhoneMask(_ raw: String) -> String {
        let d = raw.filter(\.isNumber)
        let limited = String(d.prefix(10))
        var result = ""
        for (index, char) in limited.enumerated() {
            switch index {
            case 0: result.append("("); result.append(char)
            case 2: result.append(char); result.append(") ")
            case 5: result.append(char); result.append("-")
            default: result.append(char)
            }
        }
        return result
    }
}

// MARK: - Previews

#Preview("Become Owner") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            BecomeOwnerSheet()
                .themeManager(ThemeManager())
                .userSession(UserSession())
        }
}
