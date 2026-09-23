import Foundation
import CoreFoundation
import LocalAuthentication
import Supabase

// MARK: - Auth Service

@Observable
@MainActor
final class AuthService {
    var currentUser: UserProfile?
    var isLoading = false
    var errorMessage: String?

    var isAuthenticated: Bool { currentUser != nil || isGuest }
    private(set) var isGuest = false

    // MARK: - Session restore on cold launch

    func restoreSession() async {
        let t0 = CFAbsoluteTimeGetCurrent()
        print("⏱ [Auth] START")

        // ── Step 1: Load cached profile from disk — runs in <5ms, no network ──
        if let cached = Self.loadCachedProfile() {
            currentUser = cached
            print("⏱ [Auth] loaded from cache: \(cached.fullName) (\(fmt(t0))s)")
        }
        // restoreSession() returns here — sessionReady fires almost instantly.
        // Everything below runs in the background; the user already sees the app.

        // ── Step 2: Validate / refresh the Supabase session in background ──
        Task {
            guard let session = try? await supabase.auth.session else {
                // No valid session (expired or never existed)
                if currentUser != nil {
                    print("⏱ [Auth] session invalid — clearing cache and signing out (\(fmt(t0))s)")
                    Self.clearCachedProfile()
                    currentUser = nil        // → SwiftUI switches to LoginView
                }
                return
            }
            print("⏱ [Auth] session validated (\(fmt(t0))s)")

            // Fetch fresh full profile
            if let profile = try? await fetchProfile(id: session.user.id) {
                print("⏱ [Auth] full profile fetched (\(fmt(t0))s)")
                Self.saveProfile(profile)
                currentUser = profile
            } else {
                // DB unreachable but session is valid — keep showing minimal data
                let minimal = minimalProfile(from: session.user)
                if currentUser == nil { currentUser = minimal }
            }
        }
    }

    // MARK: - Profile cache (UserDefaults — instant reads)

    private static let cacheKey = "milao.cachedUserProfile"

    static func saveProfile(_ profile: UserProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }

    static func loadCachedProfile() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }

    static func clearCachedProfile() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
    }

    private func fmt(_ start: CFAbsoluteTime) -> String {
        String(format: "%.3f", CFAbsoluteTimeGetCurrent() - start)
    }

    // MARK: - Auth state stream

    func listenToAuthChanges() {
        Task {
            for await (event, _) in supabase.auth.authStateChanges {
                if event == .signedOut {
                    currentUser = nil
                    isGuest = false
                }
            }
        }
    }

    // MARK: - Email / Password

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let session = try await supabase.auth.signIn(email: email, password: password)
            let profile = (try? await fetchProfile(id: session.user.id))
                ?? minimalProfile(from: session.user)
            Self.saveProfile(profile)
            currentUser = profile
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp(email: String, password: String, fullName: String, phone: String? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            var data: [String: AnyJSON] = ["full_name": .string(fullName)]
            // Read by the handle_new_user DB trigger, which seeds profiles.phone from it.
            if let phone, !phone.trimmingCharacters(in: .whitespaces).isEmpty {
                data["phone"] = .string(phone)
            }
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: data
            )
            // Email confirmation required — no session yet, so don't enter the app.
            guard response.session != nil else {
                errorMessage = "Almost done! Check your email to confirm your account, then log in."
                return
            }
            // Wait briefly for the handle_new_user trigger to run, then fetch.
            try? await Task.sleep(nanoseconds: 800_000_000)
            let profile = (try? await fetchProfile(id: response.user.id))
                ?? minimalProfile(from: response.user)
            Self.saveProfile(profile)
            currentUser = profile
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Apple Sign-In
    // Requires "Sign In with Apple" capability in Signing & Capabilities.

    func signInWithApple(identityToken: String, nonce: String, fullName: String?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: identityToken,
                    nonce: nonce
                )
            )
            let profile = (try? await fetchProfile(id: session.user.id))
                ?? minimalProfile(from: session.user, preferredName: fullName)
            Self.saveProfile(profile)
            currentUser = profile
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Google OAuth
    // Opens a browser via ASWebAuthenticationSession — no custom URL scheme needed.
    // Requires Google provider enabled in your Supabase dashboard:
    //   Authentication → Providers → Google → enable + add client ID/secret.

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let session = try await supabase.auth.signInWithOAuth(provider: .google)
            let profile = (try? await fetchProfile(id: session.user.id))
                ?? minimalProfile(from: session.user)
            Self.saveProfile(profile)
            currentUser = profile
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Profile updates

    func updateProfile(fullName: String, username: String?, city: String?, bio: String?) async -> Bool {
        guard let userId = currentUser?.id else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        var updates: [String: AnyJSON] = ["full_name": .string(fullName)]
        updates["username"] = username.flatMap { $0.isEmpty ? nil : .string($0) } ?? .null
        updates["city"]     = city.flatMap { $0.isEmpty ? nil : .string($0) } ?? .null
        updates["bio"]      = bio.flatMap { $0.isEmpty ? nil : .string($0) } ?? .null
        do {
            try await supabase
                .from("profiles")
                .update(updates)
                .eq("id", value: userId.uuidString)
                .execute()
            if let profile = try? await fetchProfile(id: userId) {
                Self.saveProfile(profile)
                currentUser = profile
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Avatar

    /// Uploads a new profile photo, points `profiles.avatar_url` at it, refreshes
    /// `currentUser`, and best-effort deletes the previous photo from Storage.
    @discardableResult
    func updateAvatar(_ data: Data) async -> Bool {
        guard let userId = currentUser?.id else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let previousURL = currentUser?.avatarURL
            let path = "avatars/\(UUID().uuidString).jpg"
            let bucket = supabase.storage.from("listings")
            try await bucket.upload(path, data: data, options: .init(contentType: "image/jpeg"))
            let newURL = try bucket.getPublicURL(path: path).absoluteString

            try await supabase
                .from("profiles")
                .update(["avatar_url": newURL])
                .eq("id", value: userId.uuidString)
                .execute()

            if let profile = try? await fetchProfile(id: userId) {
                Self.saveProfile(profile)
                currentUser = profile
            }
            if let previousURL, let previousPath = Self.storagePath(from: previousURL) {
                _ = try? await bucket.remove(paths: [previousPath])
            }
            return true
        } catch {
            errorMessage = "Couldn't update your photo. Please check your connection and try again."
            return false
        }
    }

    private static func storagePath(from publicURL: String) -> String? {
        guard let range = publicURL.range(of: "/object/public/listings/") else { return nil }
        return String(publicURL[range.upperBound...])
    }

    // MARK: - Password reset (OTP flow)

    /// Verifies the 6-digit recovery code emailed by `resetPassword(email:)`.
    /// Requires the Supabase "Reset Password" email template to include {{ .Token }}.
    func verifyRecoveryCode(email: String, code: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await supabase.auth.verifyOTP(email: email, token: code, type: .recovery)
            return true
        } catch {
            errorMessage = "That code didn't work. Double-check it or resend a new one."
            return false
        }
    }

    /// Sets a new password for the session established by `verifyRecoveryCode`.
    func updatePassword(_ newPassword: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let user = try await supabase.auth.update(user: UserAttributes(password: newPassword))
            // The recovery flow leaves a valid session — log the user straight in.
            let profile = (try? await fetchProfile(id: user.id)) ?? minimalProfile(from: user)
            Self.saveProfile(profile)
            currentUser = profile
            // Any stored biometric credentials now hold the old password — drop them
            // so a future biometric sign-in doesn't fail silently.
            if biometricLoginEnabled { disableBiometricLogin() }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Biometric login

    private static let biometricEnabledKey = "milao.biometricLoginEnabled"

    var biometricLoginEnabled: Bool {
        UserDefaults.standard.bool(forKey: Self.biometricEnabledKey)
    }

    /// True once signed in with a password, if biometrics are available and not already enabled —
    /// the moment to offer "enable Face ID for next time".
    var canOfferBiometricLogin: Bool {
        !biometricLoginEnabled && LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    func biometricLabel() -> String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default:       return "biometric sign-in"
        }
    }

    func biometricSystemImage() -> String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID:  return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        default:       return "lock.shield"
        }
    }

    @discardableResult
    func enableBiometricLogin(email: String, password: String) -> Bool {
        do {
            try BiometricCredentialStore.save(email: email, password: password)
            UserDefaults.standard.set(true, forKey: Self.biometricEnabledKey)
            return true
        } catch {
            return false
        }
    }

    func disableBiometricLogin() {
        BiometricCredentialStore.clear()
        UserDefaults.standard.set(false, forKey: Self.biometricEnabledKey)
    }

    @discardableResult
    func signInWithBiometrics() async -> Bool {
        guard let creds = try? BiometricCredentialStore.load(reason: "Sign in to Milao") else {
            return false
        }
        await signIn(email: creds.email, password: creds.password)
        return currentUser != nil
    }

    // MARK: - Guest

    func continueAsGuest() {
        isGuest = true
    }

    // MARK: - Sign Out

    func signOut() async {
        try? await supabase.auth.signOut()
        Self.clearCachedProfile()
        currentUser = nil
        isGuest = false
    }

    // MARK: - Account deletion

    /// Requests deletion of the signed-in user's account. This does not delete anything
    /// immediately — it marks the profile `deleted_at` (via the `request_account_deletion`
    /// RPC), which also deactivates their listings and ride posts so they stop appearing
    /// to others right away, and signs the device out. The account itself is hard-deleted
    /// 30 days later by a scheduled purge job unless the user signs back in before then
    /// and cancels via `cancelAccountDeletion()`.
    @discardableResult
    func requestAccountDeletion() async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await supabase.rpc("request_account_deletion").execute()
            if biometricLoginEnabled { disableBiometricLogin() }
            Self.clearCachedProfile()
            currentUser = nil
            isGuest = false
            return true
        } catch {
            errorMessage = "Couldn't delete your account. Please check your connection and try again."
            return false
        }
    }

    /// Cancels a pending account deletion. Called from the "your account is scheduled
    /// for deletion" screen shown when a user with `deletedAt` set signs back in within
    /// the 30-day grace period and chooses to restore rather than let deletion proceed.
    @discardableResult
    func cancelAccountDeletion() async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await supabase.rpc("cancel_account_deletion").execute()
            guard let userId = currentUser?.id, let profile = try? await fetchProfile(id: userId) else {
                return false
            }
            Self.saveProfile(profile)
            currentUser = profile
            return true
        } catch {
            errorMessage = "Couldn't restore your account. Please check your connection and try again."
            return false
        }
    }

    // MARK: - Helpers

    private func fetchProfile(id: UUID) async throws -> UserProfile {
        try await supabase
            .from("profiles")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    private func minimalProfile(from user: User, preferredName: String? = nil) -> UserProfile {
        let name: String
        if let preferred = preferredName, !preferred.isEmpty {
            name = preferred
        } else if case .string(let n) = user.userMetadata["full_name"] {
            name = n
        } else {
            name = user.email ?? "User"
        }
        return UserProfile(
            id: user.id,
            fullName: name,
            username: nil,
            avatarURL: nil,
            bio: nil,
            city: nil,
            points: 0,
            reputationTier: .bronze,
            isSuspended: false,
            createdAt: Date()
        )
    }
}
