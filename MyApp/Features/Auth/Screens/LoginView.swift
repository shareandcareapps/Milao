import SwiftUI

// MARK: - Login View

struct LoginView: View {
    @Environment(AuthService.self) private var auth
    @State private var email = ""
    @State private var password = ""
    @State private var showSignup = false
    @State private var showForgotPassword = false
    @State private var revealPassword = false

    private var canSignIn: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.isEmpty
            && !auth.isLoading
    }

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 760
            let scale = LoginScale(compact: compact)

            ZStack {
                loginBackground

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
            .ignoresSafeArea(.keyboard)
        }
        .sheet(isPresented: $showSignup) {
            SignupView().environment(auth)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView().environment(auth)
        }
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

            Text("Milao")
                .font(.nunito(.black, size: scale.logoTitleSize))
                .foregroundStyle(.white)
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
                    .foregroundStyle(Color(hex: "#FFB4B4"))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }

            PrimaryButton(canSignIn ? "Sign In" : "Enter email and password", isLoading: auth.isLoading) {
                Task { await auth.signIn(email: email, password: password) }
            }
            .frame(height: scale.primaryButtonHeight)
            .disabled(!canSignIn)

            HStack(spacing: 10) {
                Rectangle().fill(.white.opacity(0.16)).frame(height: 1)
                Text("or continue with")
                    .font(.inter(.medium, size: scale.dividerSize))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                Rectangle().fill(.white.opacity(0.16)).frame(height: 1)
            }

            HStack(spacing: scale.socialSpacing) {
                socialButton(title: "Google", icon: "globe", scale: scale) {
                    Task { await auth.signInWithGoogle() }
                }

                socialButton(title: "Guest", icon: "person.crop.circle", scale: scale) {
                    auth.continueAsGuest()
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

    private func socialButton(title: String, icon: String, scale: LoginScale, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.inter(.bold, size: scale.socialFontSize))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: scale.socialHeight)
                .background(Color(hex: "#24314B").opacity(0.92), in: RoundedRectangle(cornerRadius: scale.socialCorner, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: scale.socialCorner, style: .continuous).strokeBorder(.white.opacity(0.18), lineWidth: 1))
                .contentShape(RoundedRectangle(cornerRadius: scale.socialCorner, style: .continuous))
        }
        .buttonStyle(.plain)
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
                    Text("Create an account")
                        .foregroundStyle(Theme.Colors.saffron)
                        .fontWeight(.bold)
                }
                .font(.inter(.regular, size: scale.footerFontSize))
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

    var topSpacer: CGFloat { compact ? 8 : 24 }
    var bottomSpacer: CGFloat { compact ? 6 : 16 }
    var outerSpacing: CGFloat { compact ? 10 : 18 }
    var horizontalPadding: CGFloat { compact ? 18 : 24 }
    var logoSpacing: CGFloat { compact ? 5 : 8 }
    var logoSize: CGFloat { compact ? 56 : 78 }
    var logoCorner: CGFloat { compact ? 18 : 24 }
    var logoIconSize: CGFloat { compact ? 22 : 30 }
    var logoTitleSize: CGFloat { compact ? 34 : 45 }
    var taglineSize: CGFloat { compact ? 9 : 12 }
    var cardSpacing: CGFloat { compact ? 11 : 16 }
    var cardPadding: CGFloat { compact ? 18 : 24 }
    var cardCorner: CGFloat { compact ? 28 : 34 }
    var cardTitleSize: CGFloat { compact ? 27 : 34 }
    var subtitleSize: CGFloat { compact ? 14 : 17 }
    var fieldSpacing: CGFloat { compact ? 9 : 14 }
    var fieldHeight: CGFloat { compact ? 50 : 60 }
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
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
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
