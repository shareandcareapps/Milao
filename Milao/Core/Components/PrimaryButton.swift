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
            .foregroundStyle(.white.opacity(isEnabled ? 1 : 0.55))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .contentShape(Capsule())
        }
        .glassEffect(
            .regular
                .tint(isEnabled
                      ? Theme.Colors.primary.opacity(0.82)
                      : Color.white.opacity(0.10))
                .interactive(),
            in: Capsule()
        )
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
                .contentShape(Capsule())
        }
        .glassEffect(
            .regular.tint(.white.opacity(0.10)).interactive(),
            in: Capsule()
        )
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
