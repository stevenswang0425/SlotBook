//
//  UserSession.swift
//  SlotBook
//
//  Lightweight simulated auth session for the iOS MVP.
//  Replace with Supabase Auth when the backend is wired.
//

import Foundation
import Observation
import SwiftUI

/// How the user authenticated (simulated).
enum AuthMethod: String, Codable, Sendable {
    case email
    case phone
    case apple
    case google
    case guest
    /// Hidden owner onboarding path.
    case storeOwner
}

/// Role shown in the client (mirrors backend roles loosely).
enum UserRole: String, Codable, Sendable {
    case customer
    case owner
}

/// Signed-in identity shown on Profile.
struct AppUser: Equatable, Codable, Sendable {
    var id: UUID
    var displayName: String
    var email: String?
    var phone: String?
    var method: AuthMethod
    var role: UserRole
    /// Populated when the user completed “Become a Store Owner”.
    var storeName: String?
    var storeDescription: String?

    var isOwner: Bool { role == .owner }

    static func simulated(method: AuthMethod) -> AppUser {
        switch method {
        case .email:
            return AppUser(
                id: UUID(),
                displayName: "Alex Rivera",
                email: "alex@example.com",
                phone: nil,
                method: .email,
                role: .customer,
                storeName: nil,
                storeDescription: nil
            )
        case .phone:
            return AppUser(
                id: UUID(),
                displayName: "Sam Chen",
                email: nil,
                phone: "(555) 123-4567",
                method: .phone,
                role: .customer,
                storeName: nil,
                storeDescription: nil
            )
        case .apple:
            return AppUser(
                id: UUID(),
                displayName: "Jordan Lee",
                email: "jordan@icloud.com",
                phone: nil,
                method: .apple,
                role: .customer,
                storeName: nil,
                storeDescription: nil
            )
        case .google:
            return AppUser(
                id: UUID(),
                displayName: "Taylor Kim",
                email: "taylor@gmail.com",
                phone: nil,
                method: .google,
                role: .customer,
                storeName: nil,
                storeDescription: nil
            )
        case .guest:
            return AppUser(
                id: UUID(),
                displayName: "Guest",
                email: nil,
                phone: nil,
                method: .guest,
                role: .customer,
                storeName: nil,
                storeDescription: nil
            )
        case .storeOwner:
            return AppUser(
                id: UUID(),
                displayName: "My Store",
                email: nil,
                phone: nil,
                method: .storeOwner,
                role: .owner,
                storeName: "My Store",
                storeDescription: nil
            )
        }
    }
}

/// Payload from the hidden “Become a Store Owner” form.
struct StoreOwnerSignup: Equatable, Sendable {
    var storeName: String
    var phone: String
    var email: String?
    var serviceDescription: String?
}

/// App-wide session store (simulated sign-in for now).
@Observable
@MainActor
final class UserSession {
    private enum Keys {
        static let userData = "slotbook.session.user"
    }

    /// `nil` means browsing as guest (not signed in).
    private(set) var currentUser: AppUser?

    var isSignedIn: Bool {
        currentUser != nil && currentUser?.method != .guest
    }

    var isOwner: Bool {
        currentUser?.isOwner == true
    }

    var displayName: String {
        if let store = currentUser?.storeName, currentUser?.isOwner == true {
            return store
        }
        return currentUser?.displayName ?? "Guest"
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Keys.userData),
           let user = try? JSONDecoder().decode(AppUser.self, from: data) {
            currentUser = user
        }
    }

    /// Simulated successful authentication.
    func signIn(method: AuthMethod) {
        let user = AppUser.simulated(method: method)
        currentUser = user
        persist()
        HapticFeedback.success()
    }

    /// Simulated store creation + owner role.
    func becomeStoreOwner(_ signup: StoreOwnerSignup) {
        let name = signup.storeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = signup.phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = signup.email?.trimmingCharacters(in: .whitespacesAndNewlines)
        let desc = signup.serviceDescription?.trimmingCharacters(in: .whitespacesAndNewlines)

        currentUser = AppUser(
            id: currentUser?.id ?? UUID(),
            displayName: name,
            email: (email?.isEmpty == false) ? email : currentUser?.email,
            phone: phone,
            method: .storeOwner,
            role: .owner,
            storeName: name,
            storeDescription: (desc?.isEmpty == false) ? desc : nil
        )
        persist()
        HapticFeedback.success()
    }

    /// Return to guest browsing.
    func signOut() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: Keys.userData)
        HapticFeedback.lightImpact()
    }

    /// Explicit “continue as guest” — stays signed out.
    func continueAsGuest() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: Keys.userData)
        HapticFeedback.selection()
    }

    private func persist() {
        guard let user = currentUser,
              let data = try? JSONEncoder().encode(user) else { return }
        UserDefaults.standard.set(data, forKey: Keys.userData)
    }
}

// MARK: - Environment

private struct UserSessionKey: EnvironmentKey {
    @MainActor static var defaultValue: UserSession { UserSession() }
}

extension EnvironmentValues {
    var userSession: UserSession {
        get { self[UserSessionKey.self] }
        set { self[UserSessionKey.self] = newValue }
    }
}

extension View {
    func userSession(_ session: UserSession) -> some View {
        environment(\.userSession, session)
    }
}
