import SwiftUI

// MARK: - App Theme Options

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light:  "Light"
        case .dark:   "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light:  "sun.max"
        case .dark:   "moon"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light:  .light
        case .dark:   .dark
        }
    }
}

// MARK: - Theme Manager

@Observable
final class ThemeManager {
    private(set) var theme: AppTheme
    private static let storageKey = "milao.appTheme"

    init() {
        let saved = UserDefaults.standard.string(forKey: Self.storageKey) ?? ""
        theme = AppTheme(rawValue: saved) ?? .system
    }

    func setTheme(_ newTheme: AppTheme) {
        theme = newTheme
        UserDefaults.standard.set(newTheme.rawValue, forKey: Self.storageKey)
    }

    var colorScheme: ColorScheme? { theme.colorScheme }
}
