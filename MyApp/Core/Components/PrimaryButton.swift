import SwiftUI

// MARK: - Milao Primary Button

struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button {
            guard isEnabled && !isLoading else { return }
            action()
        } label: {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.nunito(.bold, size: 16))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
            }
            .foregroundStyle(.white.opacity(isEnabled ? 1 : 0.68))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: isEnabled
                        ? [Theme.Colors.primary, Theme.Colors.accent]
                        : [Color.white.opacity(0.22), Color.white.opacity(0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .overlay(Capsule().strokeBorder(.white.opacity(isEnabled ? 0.34 : 0.18), lineWidth: 1))
            .shadow(color: isEnabled ? Theme.Colors.primary.opacity(0.28) : .clear, radius: 16, x: 0, y: 8)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .animation(.easeInOut(duration: 0.18), value: isEnabled)
        .animation(.easeInOut(duration: 0.18), value: isLoading)
    }
}

// MARK: - Secondary / Outline Button

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.nunito(.semibold, size: 16))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(.white.opacity(0.08), in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.24), lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton("Sign In") {}
        PrimaryButton("Loading...", isLoading: true) {}
        SecondaryButton("Create Account") {}
    }
    .padding()
    .background(Theme.Colors.secondary)
}
