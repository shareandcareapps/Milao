import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Hex Color Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:  (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB,
                  red:   Double(r) / 255,
                  green: Double(g) / 255,
                  blue:  Double(b) / 255)
    }

    init(lightHex: String, darkHex: String) {
        #if canImport(UIKit)
        self.init(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(Color(hex: darkHex))
                : UIColor(Color(hex: lightHex))
        })
        #else
        self.init(hex: lightHex)
        #endif
    }
}

// MARK: - NestApp / Milao Design System

enum Theme {
    enum Colors {
        static let primary = Color(hex: "#E8185C")
        static let secondary = Color(hex: "#3D5AFE")
        static let accent = Color(hex: "#FF6B6B")
        static let saffron = Color(hex: "#F4A833")

        static let background = Color(lightHex: "#F2F2F7", darkHex: "#0A0A1A")
        static let surface = Color(lightHex: "#FFFFFF", darkHex: "#14142A")
        static let card = Color(lightHex: "#FFFFFF", darkHex: "#1C1C3A")
        static let inputBackground = Color(lightHex: "#F2F2F7", darkHex: "#14142A")

        static let textPrimary = Color(lightHex: "#0A0A1A", darkHex: "#F5F5FF")
        static let textSecondary = Color(lightHex: "#3C3C54", darkHex: "#B0B0CC")
        static let textLight = Color(lightHex: "#8E8E9A", darkHex: "#6A6A8A")
        static let textMuted = Color(lightHex: "#AEAEB8", darkHex: "#4A4A6A")

        static let border = Color(lightHex: "#E8E8EE", darkHex: "#2A2A4A")
        static let success = Color(hex: "#34C759")
        static let warning = Color(hex: "#FF9500")
        static let error = Color(hex: "#FF3B30")
        static let info = Color(hex: "#007AFF")

        static let tabActive = Color(hex: "#E8185C")
        static let tabInactive = Color(lightHex: "#6B6B74", darkHex: "#FFFFFF").opacity(0.58)

        static let homeAccent = Color(hex: "#F4A833")
        static let marketAccent = Color(hex: "#FF9500")
        static let carpoolAccent = Color(hex: "#2EAD7A")
        static let newsAccent = Color(hex: "#3AA8E0")
        static let messagesAccent = Color(hex: "#7C5CFC")

        static let headerGradientLight = [Color(hex: "#87CEEB"), Color(hex: "#C5E8FA"), Color(hex: "#F0F8FF")]
        static let headerGradientDark = [Color(hex: "#0A1628"), Color(hex: "#0F1F3D"), Color(hex: "#0A0A1A")]
        static let primaryGradient = [Color(hex: "#E8185C"), Color(hex: "#FF6B8A")]
        static let secondaryGradient = [Color(hex: "#3D5AFE"), Color(hex: "#6B8AFF")]
        static let rideGradient = [Color(hex: "#3D5AFE"), Color(hex: "#1E3AD4")]
        static let successGradient = [Color(hex: "#34C759"), Color(hex: "#30B855")]
        static let shadow = Color.black.opacity(0.12)
        static let white = Color.white
    }

    enum Fonts {
        static func nunitoRegular(size: CGFloat) -> Font { .nunito(.regular, size: size) }
        static func nunitoMedium(size: CGFloat) -> Font { .nunito(.medium, size: size) }
        static func nunitoSemiBold(size: CGFloat) -> Font { .nunito(.semibold, size: size) }
        static func nunitoBold(size: CGFloat) -> Font { .nunito(.bold, size: size) }
        static func nunitoExtraBold(size: CGFloat) -> Font { .nunito(.heavy, size: size) }
        static func interRegular(size: CGFloat) -> Font { .inter(.regular, size: size) }
        static func interMedium(size: CGFloat) -> Font { .inter(.medium, size: size) }
        static func interSemiBold(size: CGFloat) -> Font { .inter(.semibold, size: size) }
        static func interBold(size: CGFloat) -> Font { .inter(.bold, size: size) }
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let screen: CGFloat = 20
        static let base: CGFloat = 16
    }

    enum Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 14
        static let card: CGFloat = 20
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
        static let xxl: CGFloat = 36
        static let panel: CGFloat = 28
        static let pill: CGFloat = 999
    }
}

// MARK: - Shared Chrome

struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark ? Theme.Colors.headerGradientDark : Theme.Colors.headerGradientLight,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

extension View {
    func appBackground() -> some View {
        background { Theme.Colors.background.ignoresSafeArea() }
    }

    func gradientHeaderBackground() -> some View {
        background { AppBackground() }
    }

    func milaoCard(cornerRadius: CGFloat = Theme.Radius.card) -> some View {
        self
            .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Theme.Colors.shadow, radius: 14, x: 0, y: 4)
    }

    func modernGlassPanel(cornerRadius: CGFloat = Theme.Radius.card) -> some View {
        self
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.55), lineWidth: 1)
            )
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Theme.Colors.shadow, radius: 18, x: 0, y: 8)
    }

    func modernGlassButton(tint: Color = Theme.Colors.primary, cornerRadius: CGFloat = Theme.Radius.pill) -> some View {
        self.glassEffect(.regular.tint(tint).interactive(), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Typography Extensions

extension Font {
    static func nunito(_ weight: Weight = .regular, size: CGFloat) -> Font {
        .custom(nunitoPostScript(for: weight), size: size)
    }

    static func inter(_ weight: Weight = .regular, size: CGFloat) -> Font {
        .custom(interPostScript(for: weight), size: size)
    }

    static func playfairDisplay(_ weight: Weight = .regular, size: CGFloat) -> Font {
        .custom(playfairPostScript(for: weight), size: size)
    }

    private static func nunitoPostScript(for weight: Weight) -> String {
        switch weight {
        case .black, .heavy: return "Nunito-Black"
        case .bold: return "Nunito-Bold"
        case .semibold: return "Nunito-SemiBold"
        case .medium: return "Nunito-Medium"
        case .light: return "Nunito-Light"
        case .ultraLight: return "Nunito-ExtraLight"
        default: return "Nunito-Regular"
        }
    }

    private static func interPostScript(for weight: Weight) -> String {
        switch weight {
        case .black, .heavy: return "Inter-ExtraBold"
        case .bold: return "Inter-Bold"
        case .semibold: return "Inter-SemiBold"
        case .medium: return "Inter-Medium"
        case .light: return "Inter-Light"
        case .ultraLight: return "Inter-ExtraLight"
        default: return "Inter-Regular"
        }
    }

    private static func playfairPostScript(for weight: Weight) -> String {
        switch weight {
        case .black, .heavy, .bold: return "PlayfairDisplay-Bold"
        case .semibold: return "PlayfairDisplay-SemiBold"
        case .medium: return "PlayfairDisplay-Medium"
        default: return "PlayfairDisplay-Regular"
        }
    }
}
