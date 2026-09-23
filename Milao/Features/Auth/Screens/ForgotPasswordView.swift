import SwiftUI
import UIKit

// MARK: - Forgot Password View (3-step flow)

struct ForgotPasswordView: View {
    @Environment(AuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep: Int = 0
    @State private var email = ""
    @State private var otpCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var resendCooldown: Int = 0
    @State private var resendTimer: Timer? = nil

    private var passwordStrength: ResetPasswordStrength {
        if newPassword.count < 6 { return .weak }
        let hasUpper = newPassword.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasDigit = newPassword.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecial = newPassword.rangeOfCharacter(from: .punctuationCharacters) != nil
            || newPassword.rangeOfCharacter(from: .symbols) != nil
        if newPassword.count >= 10 && hasUpper && hasDigit && hasSpecial { return .strong }
        if newPassword.count >= 8 && (hasUpper || hasDigit) { return .good }
        return .weak
    }

    var body: some View {
        ZStack {
            // Same gradient as LoginView
            LinearGradient(
                colors: [Color(hex: "0A1628"), Color(hex: "1A3A6C"), Theme.Colors.secondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Two orbs
            ResetOrb(size: 280, color: Theme.Colors.saffron, opacity: 0.12, blur: 85, offset: CGSize(width: 140, height: -180))
            ResetOrb(size: 220, color: Theme.Colors.accent, opacity: 0.10, blur: 75, offset: CGSize(width: -100, height: 280))

            ScrollView {
                VStack(spacing: 0) {
                    // Header row: back button only
                    headerRow
                        .padding(.top, 20)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 28)

                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("Mila").foregroundStyle(.white)
                        Text("o").foregroundStyle(Theme.Colors.primary)
                    }
                    .font(.mouldyCheese(size: 40))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 24)

                    // Animated step content
                    stepContent
                        .padding(.horizontal, Theme.Spacing.lg)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)

                    Spacer(minLength: 40)
                }
                .frame(minHeight: (UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.screen.bounds.height ?? 700) * 0.75)
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
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack {
            Button {
                if currentStep > 0 {
                    withAnimation(.easeInOut(duration: 0.3)) { currentStep -= 1 }
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .modernGlassButton(tint: .white.opacity(0.14), cornerRadius: 20)
            }

            Spacer()
        }
    }

    // MARK: - Step Content (slide transition)

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0: step0EmailCard
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        case 1: step1OTPCard
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        case 2: step2NewPasswordCard
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        default: EmptyView()
        }
    }

    // MARK: - Step 0: Email

    private var step0EmailCard: some View {
        VStack(spacing: 20) {
            // Icon
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.primary, Theme.Colors.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white)
                )

            VStack(spacing: 6) {
                Text("Forgot Password?")
                    .font(.nunito(.bold, size: 24))
                    .foregroundStyle(.white)

                Text("Enter your email to receive a reset code")
                    .font(.inter(.regular, size: 14))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
            }

            GlassTextField(
                placeholder: "Email address",
                text: $email,
                icon: "envelope",
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

            PrimaryButton("Send Reset Code", isLoading: auth.isLoading) {
                Task {
                    await auth.resetPassword(email: email)
                    withAnimation(.easeInOut(duration: 0.3)) { currentStep = 1 }
                    startResendCooldown()
                }
            }
            .disabled(!email.contains("@") || auth.isLoading)
            .opacity(email.contains("@") ? 1.0 : 0.5)
        }
        .padding(Theme.Spacing.xl)
        .background(Color(hex: "0D1830").opacity(0.88), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(.white.opacity(0.16), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 14)
    }

    // MARK: - Step 1: OTP

    private var step1OTPCard: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "00C48C"), Theme.Colors.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: "key.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white)
                )

            VStack(spacing: 6) {
                Text("Check your email")
                    .font(.nunito(.bold, size: 24))
                    .foregroundStyle(.white)

                Text("We sent a 6-digit code to")
                    .font(.inter(.regular, size: 14))
                    .foregroundStyle(.white.opacity(0.65))
                Text(email)
                    .font(.inter(.semibold, size: 14))
                    .foregroundStyle(Theme.Colors.primary)
            }
            .multilineTextAlignment(.center)

            // OTP input — one hidden field, six display boxes (auto-advance + paste support)
            OTPCodeField(code: $otpCode)

            if let msg = auth.errorMessage {
                Text(msg)
                    .font(.inter(.regular, size: 13))
                    .foregroundStyle(Theme.Colors.accent)
                    .multilineTextAlignment(.center)
            }

            PrimaryButton("Verify Code", isLoading: auth.isLoading) {
                Task {
                    if await auth.verifyRecoveryCode(email: email, code: otpCode) {
                        withAnimation(.easeInOut(duration: 0.3)) { currentStep = 2 }
                    }
                }
            }
            .disabled(otpCode.count < 6 || auth.isLoading)
            .opacity(otpCode.count == 6 ? 1.0 : 0.5)

            Button {
                if resendCooldown == 0 {
                    Task { await auth.resetPassword(email: email) }
                    startResendCooldown()
                }
            } label: {
                Text(resendCooldown > 0 ? "Resend code in \(resendCooldown)s" : "Resend code")
                    .font(.inter(.semibold, size: 14))
                    .foregroundStyle(resendCooldown > 0 ? .white.opacity(0.4) : Theme.Colors.primary)
            }
            .disabled(resendCooldown > 0)
        }
        .padding(Theme.Spacing.xl)
        .background(Color(hex: "0D1830").opacity(0.88), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(.white.opacity(0.16), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 14)
    }

    // MARK: - Step 2: New Password

    private var step2NewPasswordCard: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.accent, Color(hex: "FF6B6B")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 26))
                        .foregroundStyle(.white)
                )

            VStack(spacing: 6) {
                Text("Create new password")
                    .font(.nunito(.bold, size: 24))
                    .foregroundStyle(.white)

                Text("Choose a strong password for your account")
                    .font(.inter(.regular, size: 14))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
            }

            GlassTextField(
                placeholder: "New password",
                text: $newPassword,
                icon: "lock",
                isSecure: true,
                textContentType: .newPassword
            )

            ResetPasswordStrengthBar(strength: passwordStrength)
                .opacity(newPassword.isEmpty ? 0 : 1)
                .animation(.easeInOut(duration: 0.2), value: newPassword.isEmpty)

            GlassTextField(
                placeholder: "Confirm password",
                text: $confirmPassword,
                icon: "lock.shield",
                isSecure: true,
                textContentType: .newPassword
            )

            if newPassword != confirmPassword && !confirmPassword.isEmpty {
                Text("Passwords don't match")
                    .font(.inter(.regular, size: 14))
                    .foregroundStyle(Theme.Colors.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let msg = auth.errorMessage {
                Text(msg)
                    .font(.inter(.regular, size: 13))
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton("Reset Password", isLoading: auth.isLoading) {
                Task {
                    // Sets the new password and logs the user in via the recovery session.
                    if await auth.updatePassword(newPassword) {
                        dismiss()
                    }
                }
            }
            .disabled(newPassword.count < 8 || newPassword != confirmPassword || auth.isLoading)
            .opacity(newPassword.count >= 8 && newPassword == confirmPassword ? 1.0 : 0.5)
        }
        .padding(Theme.Spacing.xl)
        .background(Color(hex: "0D1830").opacity(0.88), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(.white.opacity(0.16), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 14)
    }


    // MARK: - Helpers

    private func startResendCooldown() {
        resendCooldown = 30
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if resendCooldown > 0 {
                    resendCooldown -= 1
                } else {
                    resendTimer?.invalidate()
                    resendTimer = nil
                }
            }
        }
    }
}

// MARK: - OTP Code Field
// One invisible TextField holds the whole code; six boxes render it.
// Typing auto-advances, backspace works naturally, and pasting a code fills all boxes.

private struct OTPCodeField: View {
    @Binding var code: String
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .foregroundStyle(.clear)
                .tint(.clear)
                .frame(width: 1, height: 1)
                .opacity(0.02)
                .onChange(of: code) { _, newValue in
                    let digits = newValue.filter(\.isNumber)
                    code = String(digits.prefix(6))
                }

            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    let digit: String = index < code.count
                        ? String(Array(code)[index])
                        : ""
                    let isActive = isFocused && index == min(code.count, 5)
                    Text(digit)
                        .font(.nunito(.bold, size: 22))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 52)
                        .background(Color.white.opacity(isActive ? 0.18 : 0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(isActive ? Theme.Colors.primary.opacity(0.55) : Color.white.opacity(0.20), lineWidth: 1.5)
                        )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }
        }
        .onAppear { isFocused = true }
    }
}

// MARK: - Reset Password Strength

private enum ResetPasswordStrength {
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

private struct ResetPasswordStrengthBar: View {
    let strength: ResetPasswordStrength

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

// MARK: - Reset Orb

private struct ResetOrb: View {
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
    ForgotPasswordView()
        .environment(AuthService())
}
