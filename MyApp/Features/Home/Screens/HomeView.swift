import SwiftUI

private struct ScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct HomeView: View {
    @Binding var isScrolledDown: Bool
    @Environment(AuthService.self) private var auth
    @State private var rideTab: RideTabType = .offering

    private var firstName: String {
        let rawName = auth.currentUser?.fullName.components(separatedBy: " ").first ?? "friend"
        return rawName.contains("@") ? String(rawName.split(separator: "@").first ?? "friend") : rawName
    }

    private var userInitials: String {
        let parts = (auth.currentUser?.fullName ?? "").components(separatedBy: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }

    var body: some View {
        ScrollView {
            GeometryReader { geo in
                Color.clear.preference(key: ScrollOffsetKey.self, value: geo.frame(in: .named("homeScroll")).minY)
            }
            .frame(height: 0)

            VStack(spacing: 0) {
                heroHeader
                communityCard
                hotRidesSection
                featuredListingsSection
            }
            .padding(.bottom, 110)
        }
        .coordinateSpace(.named("homeScroll"))
        .onPreferenceChange(ScrollOffsetKey.self) { offset in
            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                isScrolledDown = offset < -80
            }
        }
        .background(Theme.Colors.background)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Milao")
                        .font(.nunito(.black, size: 34))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("Welcome back, \(firstName)!")
                        .font(.inter(.medium, size: 15))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()

                VStack(spacing: 16) {
                    NavigationLink { SettingsView() } label: {
                        Text(userInitials.isEmpty ? "R" : userInitials.prefix(1).uppercased())
                            .font(.inter(.bold, size: 18))
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(Theme.Colors.primary, in: Circle())
                            .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                    }
                    .buttonStyle(.plain)

                    Label("35 CP", systemImage: "bolt.fill")
                        .font(.inter(.bold, size: 15))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(height: 36)
                        .background(Theme.Colors.primary, in: Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 20) {
                Text("Browse by Category")
                    .font(.nunito(.black, size: 21))
                    .foregroundStyle(Theme.Colors.textPrimary)

                HStack(spacing: 0) {
                    ForEach(HomeCategory.allCases) { category in
                        Button {} label: {
                            VStack(spacing: 12) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundStyle(category.color)
                                    .frame(height: 34)
                                Text(category.label)
                                    .font(.inter(.bold, size: 10))
                                    .tracking(0.8)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.top, 50)
        .padding(.bottom, 26)
        .background(
            LinearGradient(colors: Theme.Colors.headerGradientLight, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea(edges: .top)
        )
        .clipShape(.rect(bottomLeadingRadius: 32, bottomTrailingRadius: 32))
    }

    private var communityCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 14) {
                Text("St. Louis Desi\nCommunity!")
                    .font(.nunito(.black, size: 23))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineSpacing(2)
                Text("Connect with fellow desis in St. Louis for housing, jobs, car pooling and more...")
                    .font(.inter(.regular, size: 15))
                    .foregroundStyle(Theme.Colors.textLight)
                    .lineSpacing(5)
            }
            Spacer(minLength: 0)
            GatewayArchIllustration()
                .frame(width: 96, height: 100)
        }
        .padding(20)
        .modernGlassPanel(cornerRadius: 28)
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.top, 22)
    }

    private var hotRidesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Hot Rides")

            HStack(spacing: 24) {
                ForEach(RideTabType.allCases) { tab in
                    Button { withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) { rideTab = tab } } label: {
                        VStack(spacing: 5) {
                            Text(tab.label)
                                .font(.inter(.black, size: 14))
                                .tracking(1.4)
                                .foregroundStyle(rideTab == tab ? Theme.Colors.textPrimary : Theme.Colors.textLight)
                            Rectangle()
                                .fill(rideTab == tab ? Theme.Colors.textPrimary : .clear)
                                .frame(height: 2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.screen)

            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(sampleRides(for: rideTab)) { ride in
                        HomeRideCard(ride: ride)
                            .frame(width: 300)
                    }
                }
                .padding(.horizontal, Theme.Spacing.screen)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.top, 32)
    }

    private var featuredListingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Featured Listings")
            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(sampleListings) { listing in
                        HomeListingCard(listing: listing)
                            .frame(width: 270)
                    }
                }
                .padding(.horizontal, Theme.Spacing.screen)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.top, 34)
    }

    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.nunito(.black, size: 23))
                .foregroundStyle(Theme.Colors.textPrimary)
            Spacer()
            Button {} label: {
                Label("See all", systemImage: "chevron.right")
                    .font(.inter(.bold, size: 15))
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(Theme.Colors.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.screen)
    }

    private func sampleRides(for type: RideTabType) -> [SampleRide] {
        switch type {
        case .offering:
            [SampleRide(type: .offering, from: "Ballwin", to: "SLU", date: "Jun 15", seats: 2), SampleRide(type: .offering, from: "St. Louis", to: "Airport", date: "Jun 18", seats: 3)]
        case .requesting:
            [SampleRide(type: .requesting, from: "Olivette", to: "Webster", date: "Tomorrow", seats: 1), SampleRide(type: .requesting, from: "Clayton", to: "Wash U", date: "Jun 21", seats: 1)]
        }
    }

    private var sampleListings: [SampleListing] {
        [
            SampleListing(title: "Private room near Wash U", price: "$700/mo", category: "MARKETPLACE", icon: "car.fill", color: Theme.Colors.secondary),
            SampleListing(title: "Saffron Indian Kitchen", price: "$15/plate", category: "FOOD", icon: "fork.knife", color: Theme.Colors.marketAccent),
            SampleListing(title: "Weekend Garba tickets", price: "$20", category: "EVENTS", icon: "sparkles", color: Color(hex: "#AF52DE"))
        ]
    }
}

private enum HomeCategory: CaseIterable, Identifiable {
    case stays, jobs, marketplace, food
    var id: Self { self }
    var label: String { switch self { case .stays: "STAYS"; case .jobs: "JOBS"; case .marketplace: "MARKET"; case .food: "FOOD" } }
    var icon: String { switch self { case .stays: "building.2.fill"; case .jobs: "briefcase.fill"; case .marketplace: "storefront.fill"; case .food: "fork.knife" } }
    var color: Color { switch self { case .stays: Color(hex: "#F0883E"); case .jobs: Color(hex: "#B07A4F"); case .marketplace: Theme.Colors.secondary; case .food: Color(hex: "#FF8A3D") } }
}

private enum RideTabType: CaseIterable, Identifiable {
    case offering, requesting
    var id: Self { self }
    var label: String { self == .offering ? "OFFERING" : "SEAT REQUEST" }
}

private struct SampleRide: Identifiable {
    let id = UUID()
    let type: RideTabType
    let from: String
    let to: String
    let date: String
    let seats: Int
}

private struct HomeRideCard: View {
    let ride: SampleRide
    var body: some View {
        LinearGradient(colors: ride.type == .offering ? Theme.Colors.rideGradient : [Color(hex: "#FF6B00"), Color(hex: "#FF4500")], startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        HomeRidePill(icon: ride.type == .offering ? "car.fill" : "person.fill", text: ride.type == .offering ? "Offering" : "Seat Request")
                        Spacer()
                        HomeRidePill(icon: "calendar", text: ride.date)
                        HomeRidePill(icon: "person.2.fill", text: "\(ride.seats) Seats")
                    }
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("From").font(.inter(.bold, size: 12)).foregroundStyle(.white.opacity(0.58))
                            Text(ride.from).font(.nunito(.black, size: 22)).foregroundStyle(.white).lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "arrow.right").font(.system(size: 22, weight: .bold)).foregroundStyle(.white.opacity(0.58))
                        Spacer()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("To").font(.inter(.bold, size: 12)).foregroundStyle(.white.opacity(0.58))
                            Text(ride.to).font(.nunito(.black, size: 22)).foregroundStyle(.white).lineLimit(1)
                        }
                    }
                }
                .padding(18)
            }
            .frame(height: 132)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Theme.Colors.secondary.opacity(0.24), radius: 14, x: 0, y: 6)
    }
}

private struct HomeRidePill: View {
    let icon: String
    let text: String
    var body: some View {
        Label(text, systemImage: icon)
            .font(.inter(.bold, size: 12))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(.white.opacity(0.16), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.28), lineWidth: 1))
    }
}

private struct SampleListing: Identifiable {
    let id = UUID()
    let title: String
    let price: String
    let category: String
    let icon: String
    let color: Color
}

private struct HomeListingCard: View {
    let listing: SampleListing
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                LinearGradient(colors: [listing.color.opacity(0.75), listing.color], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: listing.icon)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.76))
                Text(listing.category)
                    .font(.inter(.black, size: 12))
                    .tracking(1.2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(.black.opacity(0.42), in: Capsule())
                    .padding(12)
            }
            .frame(height: 150)
            VStack(alignment: .leading, spacing: 7) {
                Text(listing.title).font(.inter(.bold, size: 16)).foregroundStyle(Theme.Colors.textPrimary).lineLimit(1)
                Text(listing.price).font(.inter(.bold, size: 14)).foregroundStyle(Theme.Colors.primary)
            }
            .padding(13)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .milaoCard(cornerRadius: 18)
    }
}

private struct GatewayArchIllustration: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color(hex: "#5E8DBE").opacity(0.72), lineWidth: 10)
                .frame(width: 62, height: 92)
                .mask(alignment: .top) { Rectangle().frame(height: 96) }
                .padding(.bottom, 21)
            Rectangle().fill(Color(hex: "#5E8DBE").opacity(0.20)).frame(width: 105, height: 1).padding(.bottom, 22)
            HStack(alignment: .bottom, spacing: 4) {
                ForEach([18, 10, 28, 15, 9, 13, 11, 16], id: \.self) { h in
                    RoundedRectangle(cornerRadius: 1.5).fill(Color(hex: "#5E8DBE").opacity(0.25)).frame(width: 7, height: CGFloat(h))
                }
            }
        }
    }
}

#Preview {
    NavigationStack { HomeView(isScrolledDown: .constant(false)).environment(AuthService()) }
}
