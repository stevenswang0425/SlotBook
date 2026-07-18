//
//  SplashOverlay.swift
//  SlotBook
//
//  Brief in-app splash that mirrors the launch screen aesthetic.
//  System launch uses Info.plist UILaunchScreen + Background color.
//

import SwiftUI

struct SplashOverlay: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var logoScale: CGFloat = 0.85
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            SBColor.background.ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(themeManager.preset.primaryMuted(for: colorScheme))
                        .frame(width: 96, height: 96)

                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(themeManager.preset.primary(for: colorScheme))
                        .symbolRenderingMode(.hierarchical)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                Text("SlotBook")
                    .sbFontLogo()
                    .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                logoScale = 1
                logoOpacity = 1
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    SplashOverlay()
        .themeManager(ThemeManager())
}
