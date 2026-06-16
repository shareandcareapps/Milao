import SwiftUI

// MARK: - Glass-Effect Text Field (iOS 26 Liquid Glass)

struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil

    @Environment(\.colorScheme) private var colorScheme
    @State private var isRevealed = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isFocused ? Theme.Colors.primary : .secondary)
                    .frame(width: 28, height: 28)
                    .background(Theme.Colors.primary.opacity(isFocused ? 0.18 : 0.08), in: Circle())
            }

            Group {
                if isSecure && !isRevealed {
                    SecureField("", text: $text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.55)))
                } else {
                    TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.55)))
                        .keyboardType(keyboardType)
                }
            }
            .font(.inter(.regular, size: 16))
            .foregroundStyle(.white)
            .focused($isFocused)
            .if(textContentType != nil) { $0.textContentType(textContentType!) }

            if isSecure {
                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .modernGlassButton(tint: .white.opacity(0.10), cornerRadius: 16)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Spacing.base)
        .padding(.vertical, Theme.Spacing.md)
        .background(Color.white.opacity(isFocused ? 0.14 : 0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder((isFocused ? Theme.Colors.primary : .white).opacity(isFocused ? 0.55 : 0.22), lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.18), value: isFocused)
    }
}

// MARK: - Conditional modifier helper

private extension View {
    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition { transform(self) } else { self }
    }
}

#Preview {
    VStack(spacing: 12) {
        GlassTextField(placeholder: "Email", text: .constant(""), icon: "envelope")
        GlassTextField(placeholder: "Password", text: .constant("secret"), icon: "lock", isSecure: true)
    }
    .padding()
    .background(Theme.Colors.secondary)
}
