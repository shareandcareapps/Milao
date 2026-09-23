import SwiftUI
import UIKit
import AuthenticationServices
import CryptoKit

// MARK: - Login View

// On hold: Sign In with Apple requires a paid Apple Developer Program membership
// (the com.apple.developer.applesignin entitlement can't be provisioned on a
// personal/free team). Flip this back to `true` — and re-add the entitlement in
// Milao.entitlements — once the project is signed with an enrolled team.
private let appleSignInEnabled = false

struct LoginView: View {
    @Environment(AuthService.self) private var auth
    @State private var email = ""
    @State private var password = ""
    @State private var showSignup = false
    @State private var showForgotPassword = false
    @State private var revealPassword = false
    @State private var currentNonce: String?
    @State private var offerBiometric = false

    private var canSignIn: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.isEmpty
            && !auth.isLoading
    }

    var body: some View {
        ZStack {
            // Background lives outside the GeometryReader so it always fills the
            // screen — if it were inside, iOS's automatic keyboard avoidance would
            // shrink the reader's frame when the keyboard appears, exposing white
            // space above it instead of just resizing the content within.
            loginBackground

            GeometryReader { proxy in
                // With two social buttons the full-size layout only fits iPad-class heights
                let compact = proxy.size.height < 1000
                let scale = LoginScale(compact: compact)

                VStack(spacing: scale.outerSpacing) {
                    Spacer(minLength: scale.topSpacer)
                    logoSection(scale: scale)
                    loginCard(scale: scale)
                        .padding(.horizontal, scale.horizontalPadding)
                    footerSection(scale: scale)
                    Spacer(minLength: scale.bottomSpacer)
                }
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showSignup) {
            SignupView().environment(auth)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView().environment(auth)
        }
        .task { await checkBiometricAutofill() }
        .alert("Enable \(auth.biometricLabel())?", isPresented: $offerBiometric) {
            Button("Enable") {
                _ = auth.enableBiometricLogin(email: email, password: password)
            }
            Button("Not now", role: .cancel) {}
        } message: {
            Text("Sign in faster next time with \(auth.biometricLabel()).")
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // If a session already exists but the app requires re-authentication after
    // being relaunched, this lets a returning biometric user skip the form entirely.
    private func checkBiometricAutofill() async {
        guard auth.biometricLoginEnabled, auth.currentUser == nil else { return }
        _ = await auth.signInWithBiometrics()
    }

    private var loginBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#07101E"), Color(hex: "#14294F"), Color(hex: "#263FE0")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Theme.Colors.primary.opacity(0.16))
                .frame(width: 300, height: 300)
                .blur(radius: 86)
                .offset(x: 150, y: -190)

            Circle()
                .fill(Theme.Colors.messagesAccent.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: -160, y: 250)
        }
        // A dedicated leaf view for the tap-to-dismiss gesture: it sits behind every
        // control, so only taps that land on empty background actually reach it —
        // unlike attaching the gesture to the whole screen, which would swallow taps
        // meant for the text fields and buttons above it.
        .contentShape(Rectangle())
        .onTapGesture { hideKeyboard() }
    }

    private func logoSection(scale: LoginScale) -> some View {
        VStack(spacing: scale.logoSpacing) {
            ZStack {
                RoundedRectangle(cornerRadius: scale.logoCorner, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.saffron, Theme.Colors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "leaf.fill")
                    .font(.system(size: scale.logoIconSize, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: scale.logoSize, height: scale.logoSize)
            .overlay(RoundedRectangle(cornerRadius: scale.logoCorner, style: .continuous).strokeBorder(.white.opacity(0.32), lineWidth: 1))
            .shadow(color: Theme.Colors.saffron.opacity(0.28), radius: 18, x: 0, y: 8)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("Mila")
                    .foregroundStyle(.white)
                Text("o")
                    .foregroundStyle(Theme.Colors.primary)
            }
            .font(.mouldyCheese(size: scale.logoTitleSize))
            .minimumScaleFactor(0.8)

            Text("WHERE CULTURE MEETS COMMUNITY")
                .font(.inter(.bold, size: scale.taglineSize))
                .foregroundStyle(.white.opacity(0.62))
                .tracking(1.2)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private func loginCard(scale: LoginScale) -> some View {
        VStack(alignment: .leading, spacing: scale.cardSpacing) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Welcome back")
                    .font(.nunito(.black, size: scale.cardTitleSize))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text("Sign in to your community")
                    .font(.inter(.regular, size: scale.subtitleSize))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            VStack(spacing: scale.fieldSpacing) {
                LoginInputField(
                    placeholder: "you@example.com",
                    text: $email,
                    icon: "envelope",
                    height: scale.fieldHeight,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

                LoginInputField(
                    placeholder: "Your password",
                    text: $password,
                    icon: "lock",
                    height: scale.fieldHeight,
                    isSecure: !revealPassword,
                    textContentType: .password,
                    trailingIcon: revealPassword ? "eye.slash" : "eye"
                ) {
                    revealPassword.toggle()
                }

                Button {
                    showForgotPassword = true
                } label: {
                    Text("Forgot password?")
                        .font(.inter(.semibold, size: scale.linkSize))
                        .foregroundStyle(Theme.Colors.saffron)
                        .frame(height: scale.linkHeight)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            if let msg = auth.errorMessage {
                Text(msg)
                    .font(.inter(.regular, size: 12))
                    .foregroundStyle(Theme.Colors.error)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }

            PrimaryButton(canSignIn ? "Log in" : "Enter email and password", isLoading: auth.isLoading) {
                Task {
                    await auth.signIn(email: email, password: password)
                    if auth.currentUser != nil, auth.canOfferBiometricLogin {
                        offerBiometric = true
                    }
                }
            }
            .frame(height: scale.primaryButtonHeight)
            .disabled(!canSignIn)

            if auth.biometricLoginEnabled {
                Button {
                    Task { _ = await auth.signInWithBiometrics() }
                } label: {
                    Label("Sign in with \(auth.biometricLabel())", systemImage: auth.biometricSystemImage())
                        .font(.inter(.bold, size: scale.socialFontSize))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: scale.socialHeight)
                }
                .glassEffect(
                    .regular.tint(Color.white.opacity(0.08)).interactive(),
                    in: RoundedRectangle(cornerRadius: scale.socialCorner, style: .continuous)
                )
                .disabled(auth.isLoading)
                .opacity(auth.isLoading ? 0.55 : 1)
            }

            HStack(spacing: 10) {
                Rectangle().fill(.white.opacity(0.16)).frame(height: 1)
                Text("or")
                    .font(.inter(.medium, size: scale.dividerSize))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                Rectangle().fill(.white.opacity(0.16)).frame(height: 1)
            }

            VStack(spacing: scale.socialSpacing) {
                if appleSignInEnabled {
                    appleButton(scale: scale)
                }
                socialButton(title: "Continue with Google", icon: "globe", scale: scale) {
                    Task { await auth.signInWithGoogle() }
                }
            }
        }
        .padding(.horizontal, scale.cardPadding)
        .padding(.vertical, scale.cardPadding)
        .background(Color(hex: "#111A2A").opacity(0.82), in: RoundedRectangle(cornerRadius: scale.cardCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: scale.cardCorner, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.34), radius: 24, x: 0, y: 16)
    }

    private func appleButton(scale: LoginScale) -> some View {
        SignInWithAppleButton(.signIn) { request in
            let nonce = Self.randomNonceString()
            currentNonce = nonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = Self.sha256(nonce)
        } onCompletion: { result in
            guard case .success(let authorization) = result,
                  let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce
            else { return }
            let name = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            Task {
                await auth.signInWithApple(
                    identityToken: token,
                    nonce: nonce,
                    fullName: name.isEmpty ? nil : name
                )
            }
        }
        .signInWithAppleButtonStyle(.white)
        .frame(height: scale.socialHeight)
        .clipShape(RoundedRectangle(cornerRadius: scale.socialCorner, style: .continuous))
        .disabled(auth.isLoading)
        .opacity(auth.isLoading ? 0.55 : 1)
    }

    // Nonce helpers for Sign in with Apple (prevents replay attacks)
    private static func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random: UInt8 = 0
            if SecRandomCopyBytes(kSecRandomDefault, 1, &random) == errSecSuccess {
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private func socialButton(title: String, icon: String, scale: LoginScale, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.inter(.bold, size: scale.socialFontSize))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: scale.socialHeight)
                .contentShape(RoundedRectangle(cornerRadius: scale.socialCorner, style: .continuous))
        }
        .glassEffect(
            .regular.tint(Color.white.opacity(0.08)).interactive(),
            in: RoundedRectangle(cornerRadius: scale.socialCorner, style: .continuous)
        )
        .disabled(auth.isLoading)
        .opacity(auth.isLoading ? 0.55 : 1)
    }

    private func footerSection(scale: LoginScale) -> some View {
        VStack(spacing: scale.footerSpacing) {
            Button {
                showSignup = true
            } label: {
                HStack(spacing: 5) {
                    Text("New here?")
                        .foregroundStyle(.white.opacity(0.62))
                    Text("Join the Community")
                        .foregroundStyle(Theme.Colors.saffron)
                        .fontWeight(.bold)
                }
                .font(.inter(.regular, size: scale.footerFontSize))
                .frame(height: scale.footerButtonHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                auth.continueAsGuest()
            } label: {
                Text("Just looking? Explore the app")
                    .font(.inter(.medium, size: scale.footerFontSize - 2))
                    .foregroundStyle(.white.opacity(0.55))
                    .underline()
                    .frame(height: scale.footerButtonHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text("v1.0.0")
                .font(.inter(.regular, size: scale.versionSize))
                .foregroundStyle(.white.opacity(0.28))
        }
    }
}

private struct LoginScale {
    let compact: Bool

    var topSpacer: CGFloat { compact ? 8 : 32 }
    var bottomSpacer: CGFloat { compact ? 6 : 20 }
    var outerSpacing: CGFloat { compact ? 10 : 24 }
    var horizontalPadding: CGFloat { compact ? 18 : 24 }
    var logoSpacing: CGFloat { compact ? 6 : 12 }
    var logoSize: CGFloat { compact ? 60 : 84 }
    var logoCorner: CGFloat { compact ? 20 : 26 }
    var logoIconSize: CGFloat { compact ? 24 : 32 }
    var logoTitleSize: CGFloat { compact ? 34 : 46 }
    var taglineSize: CGFloat { compact ? 9 : 12 }
    var cardSpacing: CGFloat { compact ? 12 : 20 }
    var cardPadding: CGFloat { compact ? 18 : 28 }
    var cardCorner: CGFloat { compact ? 28 : 34 }
    var cardTitleSize: CGFloat { compact ? 27 : 34 }
    var subtitleSize: CGFloat { compact ? 14 : 17 }
    var fieldSpacing: CGFloat { compact ? 10 : 16 }
    var fieldHeight: CGFloat { compact ? 52 : 62 }
    var linkSize: CGFloat { compact ? 14 : 17 }
    var linkHeight: CGFloat { compact ? 26 : 32 }
    var primaryButtonHeight: CGFloat { compact ? 52 : 62 }
    var dividerSize: CGFloat { compact ? 12 : 14 }
    var socialSpacing: CGFloat { compact ? 10 : 14 }
    var socialHeight: CGFloat { compact ? 46 : 58 }
    var socialCorner: CGFloat { compact ? 16 : 20 }
    var socialFontSize: CGFloat { compact ? 14 : 17 }
    var footerSpacing: CGFloat { compact ? 2 : 6 }
    var footerFontSize: CGFloat { compact ? 14 : 17 }
    var footerButtonHeight: CGFloat { compact ? 28 : 34 }
    var versionSize: CGFloat { compact ? 11 : 13 }
}

private struct LoginInputField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String
    var height: CGFloat
    var isSecure = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var trailingIcon: String? = nil
    var trailingAction: (() -> Void)? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isFocused ? Theme.Colors.saffron : .white.opacity(0.7))
                .frame(width: 24)

            Group {
                if isSecure {
                    SecureField("", text: $text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.55)))
                } else {
                    TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.55)))
                        .keyboardType(keyboardType)
                }
            }
            .font(.inter(.regular, size: 16))
            .foregroundStyle(.white)
            .tint(Theme.Colors.saffron)
            .focused($isFocused)
            .if(textContentType != nil) { $0.textContentType(textContentType!) }

            if let trailingIcon, let trailingAction {
                Button(action: trailingAction) {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.76))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: height)
        .background(Color(hex: "#263553").opacity(0.94), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(isFocused ? Theme.Colors.saffron.opacity(0.65) : Color.white.opacity(0.14), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .animation(.easeInOut(duration: 0.16), value: isFocused)
    }
}

private extension View {
    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition { transform(self) } else { self }
    }
}

#Preview {
    LoginView().environment(AuthService())
}
