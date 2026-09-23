import SwiftUI

// MARK: - Shared empty-state placeholder for live-data lists

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var iconColor: Color = Theme.Colors.textLight
    var titleColor: Color = Theme.Colors.textPrimary
    var messageColor: Color = Theme.Colors.textSecondary
    /// When set, shows a "Try Again" button below the message — use for a failed
    /// fetch, as distinct from a genuinely empty result (leave nil for that case).
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(iconColor)
            Text(title)
                .font(.inter(.bold, size: 16))
                .foregroundStyle(titleColor)
            Text(message)
                .font(.inter(.regular, size: 13))
                .foregroundStyle(messageColor)
                .multilineTextAlignment(.center)
            if let retryAction {
                Button("Try Again", action: retryAction)
                    .font(.inter(.semibold, size: 13))
                    .foregroundStyle(Theme.Colors.primary)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Load-Failed State
// Convenience wrapper around EmptyStateView for "the fetch itself failed" —
// keeps the icon/copy/retry-button pattern consistent everywhere it's used.

struct LoadFailedView: View {
    let retryAction: () -> Void
    var message: String = "Check your connection and try again."

    var body: some View {
        EmptyStateView(
            icon: "wifi.exclamationmark",
            title: "Couldn't load",
            message: message,
            retryAction: retryAction
        )
    }
}
