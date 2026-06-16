import Foundation
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
        guard let session = try? await supabase.auth.session else { return }
        currentUser = (try? await fetchProfile(id: session.user.id))
            ?? minimalProfile(from: session.user)
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
            // Fall back to minimal profile when migrations haven't been applied yet.
            currentUser = (try? await fetchProfile(id: session.user.id))
                ?? minimalProfile(from: session.user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp(email: String, password: String, fullName: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(fullName)]
            )
            // Wait briefly for the handle_new_user trigger to run, then fetch.
            try? await Task.sleep(nanoseconds: 800_000_000)
            currentUser = (try? await fetchProfile(id: response.user.id))
                ?? minimalProfile(from: response.user)
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
            currentUser = (try? await fetchProfile(id: session.user.id))
                ?? minimalProfile(from: session.user, preferredName: fullName)
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
            currentUser = (try? await fetchProfile(id: session.user.id))
                ?? minimalProfile(from: session.user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Guest

    func continueAsGuest() {
        isGuest = true
    }

    // MARK: - Sign Out

    func signOut() async {
        try? await supabase.auth.signOut()
        currentUser = nil
        isGuest = false
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
