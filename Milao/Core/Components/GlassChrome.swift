import SwiftUI

struct GlassHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)

            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: 180, height: 180)
                .blur(radius: 18)
                .offset(x: 210, y: -70)

            Circle()
                .fill(.black.opacity(0.14))
                .frame(width: 160, height: 160)
                .blur(radius: 24)
                .offset(x: -70, y: 60)

            HStack(alignment: .bottom, spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .modernGlassButton(tint: .white.opacity(0.18), cornerRadius: 20)

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.nunito(.black, size: 30))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.inter(.medium, size: 13))
                        .foregroundStyle(.white.opacity(0.80))
                        .lineLimit(2)
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .frame(height: 158)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous)
                .strokeBorder(.white.opacity(0.20), lineWidth: 1)
        )
        .shadow(color: (colors.first ?? Theme.Colors.primary).opacity(0.28), radius: 24, x: 0, y: 14)
    }
}

struct GlassSectionHeader<Trailing: View>: View {
    let title: String
    let trailing: Trailing

    init(_ title: String, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.title = title
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.nunito(.bold, size: 20))
                .foregroundStyle(.primary)
            Spacer()
            trailing
                .buttonStyle(.glass)
                .tint(Theme.Colors.primary)
        }
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let colors: [Color]

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
            Text(title)
                .font(.inter(.bold, size: 12))
        }
        .foregroundStyle(isSelected ? .white : .primary)
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background {
            if isSelected {
                LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                    .clipShape(Capsule())
            } else {
                Capsule().fill(.white.opacity(0.05))
            }
        }
        .overlay(Capsule().strokeBorder(.white.opacity(isSelected ? 0.22 : 0.14), lineWidth: 1))
        .glassEffect(.regular.interactive(), in: Capsule())
        .shadow(color: (colors.first ?? Theme.Colors.primary).opacity(isSelected ? 0.24 : 0), radius: 12, x: 0, y: 6)
    }
}

struct EmptyCommunityState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(Theme.Colors.primary)
                .frame(width: 76, height: 76)
                .modernGlassButton(tint: Theme.Colors.primary.opacity(0.16), cornerRadius: 38)
            Text(title)
                .font(.nunito(.bold, size: 18))
            Text(message)
                .font(.inter(.regular, size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
    }
}

struct InitialsAvatar: View {
    let name: String
    let color: Color
    var size: CGFloat = 42
    /// When set to a valid image URL, shows the photo instead of initials.
    var imageURL: String? = nil

    private var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? "?"
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }

    private var initialsCircle: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.68)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                Text(initials)
                    .font(.inter(.bold, size: size * 0.32))
                    .foregroundStyle(.white)
            }
    }

    var body: some View {
        Group {
            if let imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        initialsCircle
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                initialsCircle
            }
        }
        .overlay(Circle().strokeBorder(.white.opacity(0.28), lineWidth: 1))
        .shadow(color: color.opacity(0.25), radius: 12, x: 0, y: 7)
    }
}
