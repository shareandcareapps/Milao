import SwiftUI
import CoreText
import Auth
import Supabase

// MARK: - App Entry Point

@main
struct MilaoApp: App {
    @UIApplicationDelegateAdaptor(MilaoAppDelegate.self) private var appDelegate
    @State private var themeManager = ThemeManager()
    @State private var auth = AuthService()
    @State private var listingsService = ListingsService()
    @State private var ridesService = RidesService()
    @State private var newsService = NewsService()
    @State private var messagesService = MessagesService()
    @State private var adminService = AdminService()
    @State private var pushService = PushNotificationService()
    @State private var blockedUsersService = BlockedUsersService()
    @State private var networkMonitor = NetworkMonitor()
    @State private var router = AppRouter()
    @State private var sessionReady = false

    init() {
        FontLoader.registerBundleFonts()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // RootView ALWAYS renders underneath — TabView, HomeView, GeometryReader
                // all initialize while the splash is still visible, so when the splash
                // fades there is nothing left to init and zero freeze.
                RootView()

                // Splash is purely a visual overlay. It fades out; content below it
                // has already been fully laid out by the time the fade completes.
                if !sessionReady {
                    Color(hex: "#1A1A1A")
                        .ignoresSafeArea()
                        .overlay {
                            Text("Milao")
                                .font(.mouldyCheese(size: 52))
                                .foregroundStyle(.white)
                        }
                        .transition(.opacity)
                        .allowsHitTesting(true)
                }
            }
            .overlay(alignment: .top) {
                if sessionReady && !networkMonitor.isConnected {
                    OfflineBanner()
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.4), value: sessionReady)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: networkMonitor.isConnected)
            .environment(themeManager)
            .environment(auth)
            .environment(listingsService)
            .environment(ridesService)
            .environment(newsService)
            .environment(messagesService)
            .environment(adminService)
            .environment(pushService)
            .environment(blockedUsersService)
            .environment(networkMonitor)
            .environment(router)
            .preferredColorScheme(themeManager.colorScheme)
            .task {
                let t0 = CFAbsoluteTimeGetCurrent()
                print("⏱ [App] task START")
                await auth.restoreSession()
                print("⏱ [App] restoreSession returned (\(String(format: "%.3f", CFAbsoluteTimeGetCurrent()-t0))s)")
                auth.listenToAuthChanges()
                sessionReady = true
                print("⏱ [App] sessionReady=true (\(String(format: "%.3f", CFAbsoluteTimeGetCurrent()-t0))s)")
                if auth.isAuthenticated {
                    await pushService.requestAuthorizationIfNeeded()
                }
            }
            .onOpenURL { url in
                Task { try? await supabase.auth.session(from: url) }
            }
            .onChange(of: auth.currentUser?.id) { _, newValue in
                guard newValue != nil else { return }
                Task { await pushService.requestAuthorizationIfNeeded() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .milaoDidRegisterDeviceToken)) { note in
                guard let tokenData = note.object as? Data, let userId = auth.currentUser?.id else { return }
                Task { await pushService.registerDeviceToken(tokenData, userId: userId) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .milaoDidTapNotification)) { note in
                guard let userInfo = note.object as? [AnyHashable: Any],
                      let type = userInfo["type"] as? String
                else { return }
                switch type {
                case "message": router.selectedTab = .messages
                case "ride":    router.selectedTab = .carpool
                default: break
                }
            }
        }
    }
}

// MARK: - Auth Gate

private struct RootView: View {
    @Environment(AuthService.self) private var auth
    @AppStorage("milao.hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        if !hasSeenOnboarding {
            OnboardingView {
                hasSeenOnboarding = true
            }
        } else if auth.isAuthenticated {
            if auth.currentUser?.isPendingDeletion == true {
                AccountPendingDeletionView()
            } else {
                RootTabView()
            }
        } else {
            LoginView()
        }
    }
}

// MARK: - Root Tab Navigation

struct RootTabView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AuthService.self) private var auth
    @Environment(MessagesService.self) private var messagesService

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            Tab(AppTab.home.label,     systemImage: AppTab.home.icon,     value: AppTab.home) {
                NavigationStack { HomeView(isScrolledDown: .constant(false)) }
            }
            Tab(AppTab.market.label,   systemImage: AppTab.market.icon,   value: AppTab.market) {
                ClassifiedsView()
            }
            Tab(AppTab.carpool.label,  systemImage: AppTab.carpool.icon,  value: AppTab.carpool) {
                CarpoolView()
            }
            Tab(AppTab.messages.label, systemImage: AppTab.messages.icon, value: AppTab.messages) {
                MessagesView()
            }
            .badge(messagesService.unreadCount)
        }
        // iOS 26: system TabView auto-applies Liquid Glass — no custom bar needed
        .tint(Theme.Colors.primary)
        .task {
            if let myId = auth.currentUser?.id {
                await messagesService.refreshUnreadCount(userId: myId)
            }
        }
        .onChange(of: router.selectedTab) { _, _ in
            Task {
                if let myId = auth.currentUser?.id {
                    await messagesService.refreshUnreadCount(userId: myId)
                }
            }
        }
    }
}

// MARK: - Tab Enum

// MARK: - Font Loader

private enum FontLoader {
    static func registerBundleFonts() {
        var fontURLs: [URL] = []
        for ext in ["ttf", "otf"] {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                fontURLs.append(contentsOf: urls)
            }
        }
        guard !fontURLs.isEmpty else { return }
        CTFontManagerRegisterFontURLs(fontURLs as CFArray, .process, true, nil)
    }
}

// MARK: - App Router
// Lets any view (e.g. Home's "See all" buttons) switch the active root tab.

@Observable
final class AppRouter {
    var selectedTab: AppTab = .home
    // Consumed by ClassifiedsView on appear, then cleared.
    var pendingListingCategory: ListingCategory?
}

// MARK: - Tab Enum

enum AppTab: Int, CaseIterable, Hashable, Identifiable {
    case home, market, carpool, messages
    var id: Self { self }

    var title: String {
        switch self {
        case .home:     "HOME"
        case .market:   "CLASSIFIEDS"
        case .carpool:  "RIDES"
        case .messages: "INBOX"
        }
    }

    // Native iOS caption label — title case, matches Phone/WhatsApp style
    var label: String {
        switch self {
        case .home:     "Home"
        case .market:   "Classifieds"
        case .carpool:  "Rides"
        case .messages: "Inbox"
        }
    }

    var icon: String {
        switch self {
        case .home:     "house"
        case .market:   "square.grid.2x2"
        case .carpool:  "car"
        case .messages: "bubble.left.and.bubble.right"
        }
    }

    var activeIcon: String {
        switch self {
        case .home:     "house.fill"
        case .market:   "square.grid.2x2.fill"
        case .carpool:  "car.fill"
        case .messages: "bubble.left.and.bubble.right.fill"
        }
    }

    var accent: Color {
        switch self {
        case .home:     Theme.Colors.homeAccent
        case .market:   Theme.Colors.marketAccent
        case .carpool:  Theme.Colors.carpoolAccent
        case .messages: Theme.Colors.messagesAccent
        }
    }
}
