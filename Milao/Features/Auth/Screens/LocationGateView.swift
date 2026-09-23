import SwiftUI
import UIKit

// Replaces zip-code collection at signup: confirms the account is being created
// in or around St. Louis, MO before it's allowed through.
struct LocationGateView: View {
    let onAllowed: () -> Void
    let onCancelled: () -> Void

    @State private var service = LocationGateService()
    @State private var phase: Phase = .intro

    private enum Phase: Equatable {
        case intro
        case checking
        case deniedPermission
        case outOfArea(miles: Int)
        case unavailable
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "080B17"), Theme.Colors.secondary, Color(hex: "1A3A6C")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Theme.Colors.carpoolAccent.opacity(0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 78)
                .offset(x: 150, y: -170)

            VStack(spacing: Theme.Spacing.xxl) {
                Spacer()

                infoCard
                    .padding(.horizontal, Theme.Spacing.lg)

                VStack(spacing: Theme.Spacing.md) {
                    actionButtons
                }
                .padding(.horizontal, Theme.Spacing.xl)

                Spacer()

                footNote
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: phase)
        .presentationDetents([.fraction(0.75)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Info card (icon + copy, varies by phase)

    private var infoCard: some View {
        VStack(spacing: Theme.Spacing.lg) {
            switch phase {
            case .intro:
                gateIcon("location.fill", colors: [Theme.Colors.carpoolAccent, Theme.Colors.secondary])
                copy(
                    title: "Confirm Your Area",
                    body: "Milao is built for the St. Louis desi community. We'll use your location just once to confirm you're in or around the metro area."
                )
            case .checking:
                ProgressView().tint(.white).scaleEffect(1.3)
                Text("Checking your location…")
                    .font(.inter(.medium, size: 15))
                    .foregroundStyle(.white.opacity(0.8))
            case .deniedPermission:
                gateIcon("location.slash.fill", colors: [Theme.Colors.error, Theme.Colors.accent])
                copy(
                    title: "Location Access Needed",
                    body: "We can't confirm you're in the St. Louis area without location access. Enable it for Milao in Settings, then try again."
                )
            case .outOfArea(let miles):
                gateIcon("map.fill", colors: [Theme.Colors.saffron, Theme.Colors.accent])
                copy(
                    title: "Outside Our Area",
                    body: "Milao is currently only available in and around St. Louis, MO. You're about \(miles) miles away — we'll let you know when Milao expands to your area."
                )
            case .unavailable:
                gateIcon("exclamationmark.triangle.fill", colors: [Theme.Colors.warning, Theme.Colors.accent])
                copy(
                    title: "Couldn't Get Your Location",
                    body: "Something went wrong finding your location. Check your connection and try again."
                )
            }
        }
        .padding(Theme.Spacing.xl)
        .modernGlassPanel(cornerRadius: 34)
    }

    private func copy(title: String, body: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Text(title)
                .font(.nunito(.black, size: 26))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(body)
                .font(.inter(.regular, size: 14))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func gateIcon(_ systemName: String, colors: [Color]) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 36, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 80, height: 80)
            .background(
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 26, style: .continuous)
            )
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(.white.opacity(0.28), lineWidth: 1))
    }

    // MARK: - Actions (vary by phase)

    @ViewBuilder
    private var actionButtons: some View {
        switch phase {
        case .intro:
            PrimaryButton("Allow Location Access") { Task { await check() } }
            SecondaryButton("Cancel") { onCancelled() }
        case .checking:
            EmptyView()
        case .deniedPermission:
            PrimaryButton("Open Settings") { openSettings() }
            SecondaryButton("Cancel") { onCancelled() }
        case .outOfArea:
            SecondaryButton("Close") { onCancelled() }
        case .unavailable:
            PrimaryButton("Try Again") { Task { await check() } }
            SecondaryButton("Cancel") { onCancelled() }
        }
    }

    private var footNote: some View {
        Text("Your location is only used to confirm eligibility and is never posted publicly.")
            .font(.inter(.regular, size: 11))
            .foregroundStyle(.white.opacity(0.38))
            .multilineTextAlignment(.center)
    }

    // MARK: - Location check

    private func check() async {
        phase = .checking
        switch await service.checkLocation() {
        case .inArea:
            onAllowed()
        case .outOfArea(let distanceMiles):
            phase = .outOfArea(miles: Int(distanceMiles.rounded()))
        case .permissionDenied:
            phase = .deniedPermission
        case .unavailable:
            phase = .unavailable
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    LocationGateView(onAllowed: {}, onCancelled: {})
}
