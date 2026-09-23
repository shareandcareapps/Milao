import Foundation
import UserNotifications
import UIKit
import Supabase

// On hold, mirroring Sign In with Apple: actually receiving remote pushes needs
// the Push Notifications capability and its `aps-environment` entitlement, which
// (like com.apple.developer.applesignin) can't be provisioned on a personal/free
// Apple Developer team. Flip this to `true` — and add the Push Notifications
// capability back in Milao.entitlements — once the project is signed with an
// enrolled team. Everything below is otherwise fully wired: it just never runs
// while this is `false`, so it can't fail a build or a runtime permission check.
let pushNotificationsEnabled = false

/// Bridges APNs device-token registration into SwiftUI. Owned by `MilaoApp` and
/// installed as `UNUserNotificationCenterDelegate` from `MilaoAppDelegate`.
@Observable
@MainActor
final class PushNotificationService: NSObject {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// Call once per app session after a user is signed in (see `MilaoApp.task`).
    /// Only ever prompts once — repeated calls are cheap no-ops after that.
    func requestAuthorizationIfNeeded() async {
        guard pushNotificationsEnabled else { return }
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        guard settings.authorizationStatus == .notDetermined else { return }
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            authorizationStatus = granted ? .authorized : .denied
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            authorizationStatus = .denied
        }
    }

    /// Called from `MilaoApp` when `MilaoAppDelegate` receives a device token.
    func registerDeviceToken(_ tokenData: Data, userId: UUID) async {
        let token = tokenData.map { String(format: "%02x", $0) }.joined()
        let payload: [String: AnyJSON] = [
            "user_id":    .string(userId.uuidString),
            "token":      .string(token),
            "platform":   .string("ios"),
            "updated_at": .string(ISO8601DateFormatter().string(from: Date())),
        ]
        _ = try? await supabase
            .from("device_tokens")
            .upsert(payload, onConflict: "user_id,token")
            .execute()
    }
}

// MARK: - APNs delegate bridging
//
// SwiftUI has no native hook for `didRegisterForRemoteNotificationsWithDeviceToken`
// or foreground notification presentation — both still require a UIApplicationDelegate.

final class MilaoAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = NotificationPresentationDelegate.shared
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationCenter.default.post(name: .milaoDidRegisterDeviceToken, object: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("⚠️ [Push] registration failed: \(error.localizedDescription)")
    }
}

/// Shows notification banners while the app is foregrounded, and turns a tapped
/// notification into a coarse in-app deep link (switch to the relevant tab) via
/// `AppRouter` — see `.milaoDidTapNotification` handling in ContentView.swift.
final class NotificationPresentationDelegate: NSObject, UNUserNotificationCenterDelegate {
    @MainActor static let shared = NotificationPresentationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        NotificationCenter.default.post(
            name: .milaoDidTapNotification,
            object: response.notification.request.content.userInfo
        )
    }
}

extension Notification.Name {
    static let milaoDidRegisterDeviceToken = Notification.Name("milaoDidRegisterDeviceToken")
    static let milaoDidTapNotification = Notification.Name("milaoDidTapNotification")
}
