import SwiftUI
import UIKit

// MARK: - Signup View

struct SignupView: View {
    @Environment(AuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showAgeGate = false
    @State private var ageGateCleared = false
    @State private var showLocationGate = false
    @State private var locationCleared = false

    private var passwordStrength: PasswordStrength {
        if password.count < 6 { return .weak }
        let hasUpper = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasDigit = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecial = password.rangeOfCharacter(from: .punctuationCharacters) != nil
            || password.rangeOfCharacter(from: .symbols) != nil
        if password.count >= 10 && hasUpper && hasDigit && hasSpecial { return .strong }
        if password.count >= 8 && (hasUpper || hasDigit) { return .good }
        return .weak
    }

    private var isValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty
            && email.contains("@")
            && password.count >= 8
            && password == confirmPassword
    }

    var body: some View {
        ZStack {
            // Background gradient (reversed compared to login)
            LinearGradient(
                colors: [Color(hex: "3D5AFE"), Color(hex: "1A3A6C"), Color(hex: "0A1628")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Floating orbs
            FloatingSignupOrb(size: 300, color: Color(hex: "F4A833"), opacity: 0.10, blur: 90, offset: CGSize(width: -130, height: -160))
            FloatingSignupOrb(size: 250, color: Color(hex: "FF6B6B"), opacity: 0.12, blur: 80, offset: CGSize(width: 140, height: 200))
            FloatingSignupOrb(size: 180, color: Color(hex: "3D5AFE"), opacity: 0.15, blur: 70, offset: CGSize(width: -60, height: 350))

            ScrollView {
                VStack(spacing: 0) {
                    // Top row: back + mini logo
                    topRow
                        .padding(.top, 16)
                        .padding(.horizontal, Theme.Spacing.lg)

                    // Headline
                    headlineSection
                        .padding(.top, 20)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 24)

                    // Glass form card
                    formCard
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 40)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { hideKeyboard() }
                        .font(.inter(.semibold, size: 15))
                }
            }
        }
        .sheet(isPresented: $showAgeGate) {
            AgeGateView(
                onConfirmed: {
                    ageGateCleared = true
                    showAgeGate = false
                    showLocationGate = true
                },
                onDenied: {
                    showAgeGate = false
                }
            )
        }
        .sheet(isPresented: $showLocationGate) {
            LocationGateView(
                onAllowed: {
                    locationCleared = true
                    showLocationGate = false
                    Task { await auth.signUp(email: email, password: password, fullName: fullName, phone: phone) }
                },
                onCancelled: {
                    showLocationGate = false
                }
            )
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Top Row

    private var topRow: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .modernGlassButton(tint: .white.opacity(0.14), cornerRadius: 18)
            }

            Spacer()

            // Mini logo
            HStack(spacing: 8) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.primary, Theme.Colors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.white)
                    )

                Text("Milao")
                    .font(.nunito(.black, size: 18))
                    .foregroundStyle(.white)
            }

            Spacer()

            // Balance spacer
            Color.clear.frame(width: 36, height: 36)
        }
    }

    // MARK: - Headline

    private var headlineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Join the community")
                .font(.nunito(.black, size: 30))
                .foregroundStyle(.white)

            Text("A space for minority communities across the USA")
                .font(.inter(.regular, size: 15))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Form Card

    private var formCard: some View {
        VStack(spacing: 14) {
            GlassTextField(
                placeholder: "Full Name",
                text: $fullName,
                icon: "person",
                textContentType: .name
            )
            .autocorrectionDisabled()

            GlassTextField(
                placeholder: "Email",
                text: $email,
                icon: "envelope",
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

            GlassTextField(
                placeholder: "Phone (optional)",
                text: $phone,
                icon: "phone",
                keyboardType: .phonePad,
                textContentType: .telephoneNumber
            )

            VStack(alignment: .leading, spacing: 6) {
                GlassTextField(
                    placeholder: "Password (min 8 characters)",
                    text: $password,
                    icon: "lock",
                    isSecure: true,
                    textContentType: .newPassword
                )

                // Password strength bar
                PasswordStrengthBar(strength: passwordStrength)
                    .opacity(password.isEmpty ? 0 : 1)
                    .animation(.easeInOut(duration: 0.2), value: password.isEmpty)
            }

            GlassTextField(
                placeholder: "Confirm Password",
                text: $confirmPassword,
                icon: "lock.shield",
                isSecure: true,
                textContentType: .newPassword
            )

            // Mismatch error
            if password != confirmPassword && !confirmPassword.isEmpty {
                Text("Passwords don't match")
                    .font(.inter(.regular, size: 13))
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Auth error
            if let errorMessage = auth.errorMessage {
                Text(errorMessage)
                    .font(.inter(.regular, size: 13))
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Location note — sets expectations before the location prompt appears
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 11))
                Text("We'll confirm you're in the St. Louis area before your account is created.")
            }
            .font(.inter(.regular, size: 12))
            .foregroundStyle(.white.opacity(0.5))
            .multilineTextAlignment(.center)

            // Terms note
            HStack(spacing: 4) {
                Text("By creating an account you agree to our")
                    .foregroundStyle(.white.opacity(0.45))
                Text("Terms")
                    .foregroundStyle(Theme.Colors.primary)
                Text("and")
                    .foregroundStyle(.white.opacity(0.45))
                Text("Privacy Policy")
                    .foregroundStyle(Theme.Colors.primary)
            }
            .font(.inter(.regular, size: 11))
            .multilineTextAlignment(.center)

            PrimaryButton("Create Account", isLoading: auth.isLoading) {
                if !ageGateCleared {
                    showAgeGate = true
                } else if !locationCleared {
                    showLocationGate = true
                } else {
                    Task { await auth.signUp(email: email, password: password, fullName: fullName, phone: phone) }
                }
            }
            .disabled(!isValid || auth.isLoading)
            .opacity(isValid ? 1.0 : 0.5)
        }
        .padding(Theme.Spacing.xl)
        .background(Color(hex: "0D1830").opacity(0.88), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(.white.opacity(0.16), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 14)
    }
}

// MARK: - Password Strength

private enum PasswordStrength {
    case weak, good, strong

    var label: String {
        switch self {
        case .weak:   "Weak"
        case .good:   "Good"
        case .strong: "Strong"
        }
    }

    var color: Color {
        switch self {
        case .weak:   Color(hex: "FF6B6B")
        case .good:   Color(hex: "F4A833")
        case .strong: Color(hex: "00C48C")
        }
    }

    var segments: Int {
        switch self {
        case .weak:   1
        case .good:   2
        case .strong: 3
        }
    }
}

private struct PasswordStrengthBar: View {
    let strength: PasswordStrength

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < strength.segments ? strength.color : Color.white.opacity(0.2))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.25), value: strength.segments)
            }

            Text(strength.label)
                .font(.inter(.medium, size: 11))
                .foregroundStyle(strength.color)
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 2)
    }
}

// MARK: - Floating Orb

private struct FloatingSignupOrb: View {
    let size: CGFloat
    let color: Color
    let opacity: Double
    let blur: CGFloat
    let offset: CGSize

    var body: some View {
        Circle()
            .fill(color.opacity(opacity))
            .frame(width: size, height: size)
            .blur(radius: blur)
            .offset(offset)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview {
    SignupView()
        .environment(AuthService())
}
