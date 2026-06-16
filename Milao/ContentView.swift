import SwiftUI

// MARK: - App Entry Point

@main
struct MilaoApp: App {
    @State private var themeManager = ThemeManager()
    @State private var auth = AuthService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(themeManager)
                .environment(auth)
                .preferredColorScheme(themeManager.colorScheme)
                .task {
                    await auth.restoreSession()
                    auth.listenToAuthChanges()
                }
        }
    }
}

// MARK: - Auth Gate

private struct RootView: View {
    @Environment(AuthService.self) private var auth

    var body: some View {
        if auth.isAuthenticated {
            RootTabView()
        } else {
            LoginView()
        }
    }
}

// MARK: - Root Tab Navigation (Phase 2: scroll-hide on Home only)

struct RootTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var homeScrolledDown = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                NavigationStack {
                    HomeView(isScrolledDown: $homeScrolledDown)
                }
                .toolbar(homeScrolledDown ? .hidden : .visible, for: .tabBar)
            }

            Tab("Market", systemImage: "storefront", value: AppTab.market) {
                ClassifiedsView()
            }

            Tab("Rides", systemImage: "car", value: AppTab.carpool) {
                CarpoolView()
            }

            Tab("News", systemImage: "newspaper", value: AppTab.news) {
                NewsView()
            }

            Tab("Inbox", systemImage: "bubble.left.and.bubble.right", value: AppTab.messages) {
                MessagesView()
            }
        }
        .tint(selectedTab.accent)
        .onChange(of: selectedTab) { _, _ in
            // Spec §4: bar must reset to visible on every tab switch
            withAnimation(.easeInOut(duration: 0.2)) { homeScrolledDown = false }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}

// MARK: - Tab Enum

enum AppTab: Int, Hashable {
    case home, market, carpool, news, messages

    var accent: Color {
        switch self {
        case .home:     Theme.Colors.homeAccent
        case .market:   Theme.Colors.marketAccent
        case .carpool:  Theme.Colors.carpoolAccent
        case .news:     Theme.Colors.newsAccent
        case .messages: Theme.Colors.messagesAccent
        }
    }
}
