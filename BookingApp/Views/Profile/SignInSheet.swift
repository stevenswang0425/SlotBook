//
//  SignInSheet.swift
//  SlotBook
//
//  Calm sign-in modal: Email, Phone, social placeholders, continue as guest.
//

import SwiftUI

struct SignInSheet: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.userSession) private var userSession

    /// Optional callback after a successful simulated sign-in.
    var onSignedIn: (() -> Void)? = nil

    @State private var isAuthenticating = false
    @State private var pendingMethod: AuthMethod?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    headerCopy

                    VStack(spacing: Spacing.sm) {
                        authOption(
                            title: "Continue with Email",
                            subtitle: "Use your email and password",
                            systemImage: "envelope.fill",
                            method: .email,
                            isPrimary: true
                        )

                        authOption(
                            title: "Continue with Phone Number",
                            subtitle: "Get a one-time code by SMS",
                            systemImage: "iphone",
                            method: .phone,
                            isPrimary: false
                        )
                    }

                    socialSection

                    continueAsGuest
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .background(SBColor.background.ignoresSafeArea())
            .navigationTitle("Sign in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(themeManager.preset.primary(for: colorScheme))
                        .disabled(isAuthenticating)
                }
            }
            .interactiveDismissDisabled(isAuthenticating)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    private var headerCopy: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Welcome to SlotBook")
                .sbFontHeadline()
            Text("Sign in to save bookings, or continue browsing as a guest.")
                .sbFontBody()
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, Spacing.xs)
    }

    private var socialSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Rectangle()
                    .fill(SBColor.border)
                    .frame(height: 1)
                Text("Coming soon")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SBColor.textTertiary)
                    .fixedSize()
                Rectangle()
                    .fill(SBColor.border)
                    .frame(height: 1)
            }
            .padding(.vertical, Spacing.xs)

            HStack(spacing: Spacing.sm) {
                socialPlaceholder(
                    title: "Apple",
                    systemImage: "apple.logo",
                    method: .apple
                )
                socialPlaceholder(
                    title: "Google",
                    systemImage: "g.circle.fill",
                    method: .google
                )
            }
        }
    }

    private var continueAsGuest: some View {
        Button {
            userSession.continueAsGuest()
            dismiss()
        } label: {
            Text("Continue as Guest")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SBColor.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(SBPressableButtonStyle())
        .disabled(isAuthenticating)
        .padding(.top, Spacing.xs)
        .accessibilityHint("Dismisses sign in and keeps browsing as guest")
    }

    // MARK: - Rows

    private func authOption(
        title: String,
        subtitle: String,
        systemImage: String,
        method: AuthMethod,
        isPrimary: Bool
    ) -> some View {
        let primary = themeManager.preset.primary(for: colorScheme)
        let muted = themeManager.preset.primaryMuted(for: colorScheme)
        let loading = isAuthenticating && pendingMethod == method

        return Button {
            simulateSignIn(method)
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                        .fill(isPrimary ? primary : muted)
                        .frame(width: 44, height: 44)

                    if loading {
                        ProgressView()
                            .tint(isPrimary ? .white : primary)
                    } else {
                        Image(systemName: systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isPrimary ? Color.white : primary)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SBColor.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(SBColor.textSecondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SBColor.textTertiary)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .fill(SBColor.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .stroke(
                        isPrimary ? primary.opacity(0.25) : SBColor.border,
                        lineWidth: 1
                    )
            )
            .sbCardShadow()
        }
        .buttonStyle(SBPressableButtonStyle())
        .disabled(isAuthenticating)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }

    private func socialPlaceholder(
        title: String,
        systemImage: String,
        method: AuthMethod
    ) -> some View {
        Button {
            // Simulated for now — same mock success path, labeled as future social.
            simulateSignIn(method)
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .foregroundStyle(SBColor.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(SBColor.border, lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .fill(SBColor.card)
                    )
            )
        }
        .buttonStyle(SBPressableButtonStyle())
        .disabled(isAuthenticating)
        .opacity(isAuthenticating ? 0.5 : 1)
        .accessibilityLabel("Continue with \(title)")
        .accessibilityHint("Simulated sign-in for now")
    }

    // MARK: - Simulate auth

    private func simulateSignIn(_ method: AuthMethod) {
        guard !isAuthenticating else { return }
        pendingMethod = method
        isAuthenticating = true

        Task {
            // Brief pause so the loading state is visible.
            try? await Task.sleep(for: .milliseconds(650))
            userSession.signIn(method: method)
            isAuthenticating = false
            pendingMethod = nil
            onSignedIn?()
            dismiss()
        }
    }
}

// MARK: - Previews

#Preview("Sign In Sheet") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            SignInSheet()
                .themeManager(ThemeManager())
                .userSession(UserSession())
        }
}
