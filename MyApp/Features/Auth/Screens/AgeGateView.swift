import SwiftUI

// Per spec §6: Age gate must complete before any account creation finishes.
struct AgeGateView: View {
    let onConfirmed: () -> Void
    let onDenied: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "080B17"), Theme.Colors.secondary, Color(hex: "1A3A6C")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Theme.Colors.primary.opacity(0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 78)
                .offset(x: 150, y: -170)

            VStack(spacing: Theme.Spacing.xxl) {
                Spacer()

                VStack(spacing: Theme.Spacing.lg) {
                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 96, height: 96)
                        .modernGlassButton(tint: Theme.Colors.primary.opacity(0.20), cornerRadius: 30)

                    VStack(spacing: Theme.Spacing.md) {
                        Text("Age Confirmation")
                            .font(.nunito(.black, size: 30))
                            .foregroundStyle(.white)

                        Text("Are you 13 years of age or older?")
                            .font(.inter(.semibold, size: 17))
                            .foregroundStyle(.white.opacity(0.84))
                            .multilineTextAlignment(.center)

                        Text("Milao is only available to users who are 13 or older.")
                            .font(.inter(.regular, size: 13))
                            .foregroundStyle(.white.opacity(0.56))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(Theme.Spacing.xl)
                .modernGlassPanel(cornerRadius: 34)
                .padding(.horizontal, Theme.Spacing.lg)

                VStack(spacing: Theme.Spacing.md) {
                    PrimaryButton("Yes, I am 13 or older") {
                        onConfirmed()
                    }

                    SecondaryButton("No, I am under 13") {
                        onDenied()
                    }
                }
                .padding(.horizontal, Theme.Spacing.xl)

                Spacer()

                Text("You must be at least 13 years old to create a Milao account.")
                    .font(.inter(.regular, size: 11))
                    .foregroundStyle(.white.opacity(0.38))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .presentationDetents([.fraction(0.75)])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    AgeGateView(onConfirmed: {}, onDenied: {})
}
