import SwiftUI

/// App-wide "you're offline" indicator — see `NetworkMonitor` and its use in
/// ContentView.swift. Purely informational; screens keep their own fetch-error
/// states (LoadFailedView, alerts) for surfacing what actually failed.
struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 12, weight: .semibold))
            Text("You're offline")
                .font(.inter(.semibold, size: 13))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.85), in: Capsule())
        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)
    }
}
