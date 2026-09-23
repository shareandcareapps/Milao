import SwiftUI

private struct ScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}


struct HomeView: View {
    @Binding var isScrolledDown: Bool
    @Environment(AuthService.self) private var auth
    @Environment(RidesService.self) private var ridesService
    @Environment(ListingsService.self) private var listingsService
    @Environment(AppRouter.self) private var router
    @State private var rideTab: RideTabType = .offering
    @State private var currentRideID: SampleRide.ID? = nil
    @State private var showingPostRide = false
    @State private var showSignInPrompt = false

    @State private var allRides: [SampleRide] = []
    @State private var homeListings: [SampleListing] = []
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    // Figma-exact colors
    private let navyBlue = Color(hex: "#0A2463")
    private var pageBg: Color        { isDark ? Color(red: 0.16, green: 0.16, blue: 0.16) : .white }
    private var textPrimary: Color   { isDark ? Color(hex: "#E4E4E4") : Color(hex: "#100D0D") }
    private var textSecondary: Color { isDark ? Color(hex: "#909090") : Color(hex: "#5C5C66") }

    private var firstName: String {
        let raw = auth.currentUser?.fullName.components(separatedBy: " ").first ?? "friend"
        return raw.contains("@") ? String(raw.split(separator: "@").first ?? "friend") : raw
    }

    private var userInitials: String {
        let parts = (auth.currentUser?.fullName ?? "").components(separatedBy: " ")
        let f = parts.first?.first.map(String.init) ?? ""
        let l = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (f + l).uppercased()
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ScrollOffsetKey.self,
                        value: geo.frame(in: .named("homeScroll")).minY
                    )
                }
                .frame(height: 0)

                VStack(spacing: 0) {
                    // Hero header + browse share pageBg so clipped corners reveal white
                    VStack(spacing: 0) {
                        heroHeader(topInset: proxy.safeAreaInsets.top)
                        browseSection
                            .background(pageBg)
                            .zIndex(1)
                    }
                    .background(pageBg)

                    VStack(spacing: 0) {
                        communitySection
                            .padding(.top, 40)
                        hotRidesSection
                            .padding(.top, -60)
                            .zIndex(1)
                        featuredListingsSection

                        // Footer fade
                        LinearGradient(
                            stops: [
                                .init(color: pageBg, location: 0),
                                .init(color: pageBg, location: 0.2),
                                .init(color: isDark ? Color(hex: "#0A0A0A") : navyBlue, location: 1.0)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(height: 160)
                    }
                    .background(pageBg)
                }
                .padding(.bottom, 0)
            }
            .ignoresSafeArea(edges: .top)
            .coordinateSpace(.named("homeScroll"))
            .onPreferenceChange(ScrollOffsetKey.self) { offset in
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    isScrolledDown = offset < -80
                }
            }
        }
        .background(isDark ? Color(red: 0.16, green: 0.16, blue: 0.16) : navyBlue)
        .toolbar(.hidden, for: .navigationBar)
        .task { await loadHomeData() }
        .signInPrompt(isPresented: $showSignInPrompt)
        .sheet(isPresented: $showingPostRide) { PostRideView() }
        .onChange(of: showingPostRide) { wasShowing, isShowing in
            if wasShowing && !isShowing { Task { await loadHomeData() } }
        }
    }

    private func loadHomeData() async {
        async let rides = ridesService.fetchHome()
        async let listings = listingsService.fetchHome()
        allRides = await rides.map(SampleRide.init)
        homeListings = await listings.map(SampleListing.init)
    }

    // MARK: - Hero Header
    // Figma light: linear-gradient(180deg, #40C8F8 0%, #FFFFFF 100%)
    // Figma dark:  linear-gradient(360deg, #161616 0%, #2C2C2C 100%) → top=#2C2C2C, bottom=#161616

    private func heroHeader(topInset: CGFloat) -> some View {
        let milaoColor: Color  = isDark ? Color(hex: "#E4E4E4") : .white
        let nameColor: Color   = isDark ? Color(hex: "#E4E4E4") : Color.white.opacity(0.88)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("Mila")
                        .foregroundStyle(milaoColor)
                    Text("o")
                        .foregroundStyle(Theme.Colors.primary)
                }
                .font(.mouldyCheese(size: 44))
                .frame(maxHeight: .infinity, alignment: .top)

                Spacer()

                NavigationLink { SettingsView() } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 42, height: 42)
                        Text(userInitials.isEmpty ? String(firstName.prefix(1)).uppercased() : userInitials)
                            .font(.inter(.bold, size: 16))
                            .foregroundStyle(.black)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)

            // "Welcome back, Raam!" — present in Figma, was missing from old code
            Text(auth.currentUser == nil ? "Welcome! You're exploring as a guest" : "Welcome back, \(firstName)!")
                .font(.inter(.regular, size: 14))
                .foregroundStyle(nameColor)
                .padding(.horizontal, 20)
                .padding(.top, 10)
        }
        .padding(.top, topInset + 24)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            Group {
                if isDark {
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "#171717"), location: 0.00),
                            .init(color: Color(hex: "#2B2B2B"), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 1),
                        endPoint: UnitPoint(x: 0.5, y: 0)
                    )
                } else {
                    navyBlue
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
                style: .continuous
            )
        )
    }

    // MARK: - Browse by Category
    // Figma light: background #FFFFFF, border-radius 0 0 60 60, box-shadow 0px 4px 4px rgba(0,0,0,0.25)
    // Figma dark:  background #161616, box-shadow 0px 2px 2px rgba(0,0,0,0.5)

    private var browseSection: some View {
        let sectionBg: Color  = isDark ? Color(red: 0.09, green: 0.09, blue: 0.09) : navyBlue
        let labelColor: Color = .white

        return VStack(spacing: 16) {
            Text("Browse by Category")
                .font(.inter(.bold, size: 20))
                .foregroundStyle(labelColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)

            HStack(spacing: 10) {
                ForEach(HomeCategory.allCases) { cat in
                    Button {
                        router.pendingListingCategory = cat.listingCategory
                        router.selectedTab = .market
                    } label: {
                        VStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(LinearGradient(
                                                colors: [
                                                    Color.white.opacity(isDark ? 0.15 : 0.55),
                                                    Color.clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(Color.white, lineWidth: 1)
                                    )
                                    // Single soft shadow — calmer, more premium than the old double glow
                                    .shadow(
                                        color: .black.opacity(isDark ? 0.45 : 0.18),
                                        radius: 8, x: 0, y: 4
                                    )
                                Image(cat.assetName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: cat.iconWidth, height: 35)
                            }
                            .frame(width: 62, height: 62)
                            Text(cat.label)
                                .font(.inter(.bold, size: 10))
                                .foregroundStyle(labelColor)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 80)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 15)
        .background(sectionBg)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 40,
                bottomTrailingRadius: 40,
                topTrailingRadius: 0,
                style: .continuous
            )
        )
        .shadow(
            color: .black.opacity(isDark ? 0.95 : 0.5),
            radius: isDark ? 1 : 2,
            x: 0, y: isDark ? 2 : 4
        )
        .padding(.bottom, 2)
    }

    // MARK: - Community Section

    private var communitySection: some View {
        ZStack(alignment: .topLeading) {
            pageBg.ignoresSafeArea()

            // St. Louis skyline photo — fill width, pin top so arch is never cut
            GeometryReader { geo in
                Image("StLouisSkyline")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, alignment: .top)
                    .clipped()
                    .opacity(isDark ? 0.18 : 0.5)
            }

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    // Figma: "St. Louis" Inter-Medium, "Desi Community!" Inter-ExtraBold
                    Text("St. Louis \(Text("Desi Community!").font(.inter(.heavy, size: 20)))")
                        .font(.inter(.medium, size: 20))
                        .foregroundStyle(textPrimary)

                    Text("Connect with fellow desis in St. Louis for housing, jobs, car pooling and more...")
                        .font(.inter(.regular, size: 11))
                        .foregroundStyle(textSecondary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 220)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 30)
            .padding(.top, 0)
            .padding(.bottom, 4)
        }
        .frame(minHeight: 160)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    // MARK: - Hot Rides

    private var hotRidesSection: some View {
        let labelColor: Color = isDark
            ? Color(red: 0.92, green: 0.92, blue: 0.92)
            : .white
        let cardBg: Color = isDark ? Color(red: 0.13, green: 0.13, blue: 0.13) : navyBlue
        let rides       = allRides.filter { $0.type == rideTab }
        let currentPage = rides.firstIndex(where: { $0.id == currentRideID }) ?? 0

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Hot Rides")
                    .font(.inter(.heavy, size: 17))
                    .foregroundStyle(labelColor)

                Spacer()

                Button { router.selectedTab = .carpool } label: {
                    HStack(spacing: 4) {
                        Text("See all")
                            .font(.inter(.bold, size: 12))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(Theme.Colors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                }
                .glassEffect(.regular.tint(Theme.Colors.primary.opacity(0.12)).interactive(), in: Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            HStack(spacing: 0) {
                ForEach(RideTabType.allCases) { tab in
                    HotRidesTabButton(
                        tab: tab,
                        isActive: rideTab == tab,
                        labelColor: labelColor
                    ) {
                        withAnimation(.smooth(duration: 0.22)) { rideTab = tab }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Rectangle()
                .fill(labelColor.opacity(isDark ? 0.18 : 0.14))
                .frame(height: 2)
                .padding(.top, 12)

            if rides.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "car")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(labelColor.opacity(0.7))
                    Text("No rides available right now")
                        .font(.inter(.bold, size: 15))
                        .foregroundStyle(labelColor)
                    Button {
                        if auth.currentUser == nil {
                            showSignInPrompt = true
                        } else {
                            showingPostRide = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("Add a ride")
                                .font(.inter(.bold, size: 13))
                        }
                        .foregroundStyle(labelColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                    }
                    .glassEffect(.regular.tint(Theme.Colors.primary.opacity(0.16)).interactive(), in: Capsule())
                }
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(rides) { ride in
                            HomeRideCard(ride: ride)
                                .padding(.horizontal, 16)
                                .containerRelativeFrame(.horizontal)
                                .id(ride.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $currentRideID)
                .id(rideTab)
                .transition(.opacity)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .onChange(of: rideTab) { currentRideID = nil }

                HStack(spacing: 6) {
                    ForEach(rides.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? labelColor : labelColor.opacity(0.22))
                            .frame(width: i == currentPage ? 16 : 6, height: 6)
                            .animation(.smooth(duration: 0.22), value: currentPage)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 14)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: rideTab)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: isDark ? .clear : navyBlue.opacity(0.30), radius: 16, x: 0, y: 8)
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.top, 48)
    }

    // MARK: - Featured Listings

    private var featuredListingsSection: some View {
        let cardBg: Color = isDark
            ? Color(hex: "#1A0A10").opacity(0.92)
            : navyBlue

        return VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Featured Listings")
                            .font(.inter(.heavy, size: 22))
                            .foregroundStyle(Color.white)
                        Text("Handpicked for the community")
                            .font(.inter(.regular, size: 11))
                            .foregroundStyle(Color.white.opacity(0.55))
                    }
                    Spacer()
                    Button { router.selectedTab = .market } label: {
                        HStack(spacing: 4) {
                            Text("See all")
                                .font(.inter(.bold, size: 12))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(isDark ? Theme.Colors.primary : .white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                    .glassEffect(.regular.tint(isDark ? Theme.Colors.primary.opacity(0.12) : Color.white.opacity(0.18)).interactive(), in: Capsule())
                }
                .padding(.horizontal, 4)

                if homeListings.isEmpty {
                    EmptyStateView(
                        icon: "bag",
                        title: "No listings yet",
                        message: "Featured listings will show up here once the community starts posting.",
                        iconColor: .white.opacity(0.7),
                        titleColor: .white,
                        messageColor: .white.opacity(0.7)
                    )
                    .padding(.vertical, 30)
                } else {
                    FeaturedListingsFanCarousel(listings: homeListings)
                        .padding(.horizontal, -Theme.Spacing.lg)
                }
            }
            .padding(.vertical, Theme.Spacing.lg)
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .background(cardBg, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    isDark
                        ? Color.white.opacity(0.08)
                        : Color.white.opacity(0.15),
                    lineWidth: 1
                )
        )
        .shadow(color: isDark ? Theme.Colors.primary.opacity(0.16) : navyBlue.opacity(0.35), radius: 20, x: 0, y: 8)
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.top, 24)
    }

}

// MARK: - Hot Rides Tab Button

private struct HotRidesTabButton: View {
    let tab: RideTabType
    let isActive: Bool
    let labelColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text(tab.label)
                    .font(.inter(isActive ? .heavy : .semibold, size: 12))
                    .foregroundStyle(isActive ? labelColor : labelColor.opacity(0.38))
                    .padding(.horizontal, 4)
                // Underline indicator
                Rectangle()
                    .fill(isActive ? labelColor : Color.clear)
                    .frame(height: 2)
                    .cornerRadius(1)
            }
        }
        .buttonStyle(.plain)
        .padding(.trailing, 16)
        .animation(.smooth(duration: 0.22), value: isActive)
    }
}

// MARK: - Supporting Enums & Models

private enum HomeCategory: CaseIterable, Identifiable {
    case stays, jobs, marketplace, food
    var id: Self { self }
    var label: String {
        switch self { case .stays: "STAYS"; case .jobs: "JOBS"; case .marketplace: "MARKETPLACE"; case .food: "FOOD" }
    }
    var assetName: String {
        switch self { case .stays: "CategoryStays"; case .jobs: "CategoryJobs"; case .marketplace: "CategoryMarketplace"; case .food: "CategoryFood" }
    }
    var iconWidth: CGFloat {
        switch self { case .stays: 38; case .jobs: 35; case .marketplace: 42; case .food: 34 }
    }
    var listingCategory: ListingCategory {
        switch self { case .stays: .housing; case .jobs: .jobs; case .marketplace: .buySell; case .food: .food }
    }
}

private enum RideTabType: CaseIterable, Identifiable {
    case offering, requesting
    var id: Self { self }
    var label: String { self == .offering ? "OFFERING" : "REQUESTING" }
}

private struct SampleRide: Identifiable {
    let id = UUID(); let type: RideTabType; let from: String; let to: String; let date: String; let seats: Int

    init(type: RideTabType, from: String, to: String, date: String, seats: Int) {
        self.type = type; self.from = from; self.to = to; self.date = date; self.seats = seats
    }

    init(_ ride: Ride) {
        type = ride.isOffering ? .offering : .requesting
        from = ride.fromLocation
        to = ride.toLocation
        if let d = ride.rideDate {
            let f = DateFormatter(); f.dateFormat = "MMM d"
            date = f.string(from: d)
        } else {
            date = "TBD"
        }
        seats = ride.seatsAvailable ?? 1
    }
}

private struct SampleListing: Identifiable {
    let id = UUID(); let title: String; let location: String; let category: String; let color: Color; let imageURL: String?
    init(title: String, location: String, category: String, color: Color, imageURL: String? = nil) {
        self.title = title; self.location = location; self.category = category; self.color = color; self.imageURL = imageURL
    }

    init(_ listing: Listing) {
        title = listing.title
        location = listing.metadata?.location ?? "St. Louis, MO"
        switch listing.categoryEnum {
        case .housing, .accommodation: category = "STAYS"
        case .food:                    category = "FOOD"
        case .jobs:                    category = "JOBS"
        case .buySell, .events, .all:  category = "MARKETPLACE"
        }
        color = Color(hex: listing.categoryEnum.gradientColors.first ?? "3D5AFE")
        imageURL = listing.images.first
    }
}


private extension View {
    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: - Ride Card

private struct HomeRideCard: View {
    let ride: SampleRide
    @Environment(\.colorScheme) private var colorScheme

    private let cardH: CGFloat = 90

    private var isOffering: Bool { ride.type == .offering }

    var body: some View {
        let isDark = colorScheme == .dark
        let navy = Color(hex: "#0A2463")

        let cardText: Color   = isDark ? .white : navy
        let cardSubtext: Color = isDark ? .white.opacity(0.70) : navy.opacity(0.60)
        let pillStroke: Color  = isDark ? .white : navy

        ZStack {
            if isDark {
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.15, blue: 0.72), Color(red: 0.20, green: 0.32, blue: 0.90)],
                    startPoint: .leading, endPoint: .trailing
                )
            } else {
                Color.white
            }

            VStack(alignment: .leading, spacing: 0) {

                // ── Row 1: type chip + meta pills ──
                HStack(alignment: .center, spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: isOffering ? "car.fill" : "person.wave.2.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(isOffering ? "Offering" : "Requesting")
                            .font(.inter(.bold, size: 12))
                            .lineLimit(1)
                    }
                    .fixedSize()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.Colors.primary, in: Capsule())

                    Spacer(minLength: 0)

                    HStack(spacing: 5) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11, weight: .regular))
                        Text(ride.date)
                            .font(.inter(.medium, size: 12))
                            .lineLimit(1)
                    }
                    .foregroundStyle(cardText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .overlay(Capsule().stroke(pillStroke, lineWidth: 1.2))
                    .fixedSize()

                    HStack(spacing: 5) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 10, weight: .regular))
                        Text("\(ride.seats)")
                            .font(.inter(.medium, size: 12))
                            .lineLimit(1)
                    }
                    .foregroundStyle(cardText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .overlay(Capsule().stroke(pillStroke, lineWidth: 1.2))
                    .fixedSize()
                }

                Spacer()

                // ── Row 2: From / To — equal half-width columns ──
                HStack(alignment: .bottom, spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("From")
                            .font(.inter(.regular, size: 12))
                            .foregroundStyle(cardSubtext)
                        Text(ride.from)
                            .font(.inter(.bold, size: 20))
                            .foregroundStyle(cardText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("To")
                            .font(.inter(.regular, size: 12))
                            .foregroundStyle(cardSubtext)
                        Text(ride.to)
                            .font(.inter(.bold, size: 20))
                            .foregroundStyle(cardText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
        }
        .frame(height: cardH)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: isDark
                            ? [.white.opacity(0.22), .white.opacity(0.05)]
                            : [navy.opacity(0.18), navy.opacity(0.06)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}



// MARK: - Featured Listings Fan Carousel
// Figma: center card 244×309, side cards 186×235, gap ~10pt, infinite loop

private struct FeaturedListingsFanCarousel: View {
    let listings: [SampleListing]
    @State  private var currentIndex = 0
    @State  private var dotIndex    = 0   // updates immediately on swipe; currentIndex lags until spring settles
    @GestureState private var liveOffset: CGFloat = 0
    @State  private var animOffset: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme

    private let spacing:   CGFloat = 240
    private let cardH:     CGFloat = 340
    private let sideScale: CGFloat = 0.80

    private var n: Int { listings.count }
    // Combined offset used for all positioning
    private var offset: CGFloat { animOffset + liveOffset }

    private func listing(slot: Int) -> SampleListing {
        listings[((currentIndex + slot) % n + n) % n]
    }

    private func cardScale(x: CGFloat) -> CGFloat {
        let dist = min(abs(x) / spacing, 1.0)
        return 1.0 - (1.0 - sideScale) * dist
    }

    var body: some View {
        // Section background is dark (navy in light, dark maroon in dark) — dots must always be light
        let dotColor: Color = colorScheme == .dark
            ? Color(red: 0.92, green: 0.92, blue: 0.92)
            : Color.white

        VStack(spacing: 0) {
            ZStack {
                ForEach([-2, 2], id: \.self) { slot in
                    let x = CGFloat(slot) * spacing + offset
                    FeaturedListingCard(listing: listing(slot: slot))
                        .scaleEffect(cardScale(x: x))
                        .offset(x: x)
                        .zIndex(0)
                }
                ForEach([-1, 1], id: \.self) { slot in
                    let x = CGFloat(slot) * spacing + offset
                    FeaturedListingCard(listing: listing(slot: slot))
                        .scaleEffect(cardScale(x: x))
                        .offset(x: x)
                        .zIndex(1)
                        .onTapGesture { commit(from: 0, delta: slot) }
                }
                FeaturedListingCard(listing: listings[min(currentIndex, n - 1)])
                    .scaleEffect(cardScale(x: offset))
                    .offset(x: offset)
                    .zIndex(2)
            }
            .frame(height: cardH)
            .frame(maxWidth: .infinity)
            .clipped()
            // If a refresh shrinks the list, clamp indices so we never subscript out of range
            .onChange(of: listings.count) { _, newCount in
                if currentIndex >= newCount { currentIndex = 0 }
                if dotIndex >= newCount { dotIndex = 0 }
            }

            // Page dots — same style as Hot Rides
            HStack(spacing: 6) {
                ForEach(0..<listings.count, id: \.self) { i in
                    Capsule()
                        .fill(i == dotIndex ? dotColor : dotColor.opacity(colorScheme == .dark ? 0.30 : 0.50))
                        .frame(width: i == dotIndex ? 16 : 6, height: 6)
                        .animation(.smooth(duration: 0.22), value: dotIndex)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 4)
        }
        // simultaneousGesture lets the parent ScrollView still receive vertical drags.
        // The direction lock inside ensures we only steal horizontal ones.
        .simultaneousGesture(
            DragGesture(minimumDistance: 15)
                .updating($liveOffset) { value, state, _ in
                    let h = abs(value.translation.width)
                    let v = abs(value.translation.height)
                    // Only track if clearly horizontal — vertical passes to ScrollView
                    guard h > v, h > 10 else { return }
                    state = value.translation.width
                }
                .onEnded { value in
                    let h = abs(value.translation.width)
                    let v = abs(value.translation.height)
                    // Ignore if the drag was primarily vertical
                    guard h > v else { return }
                    let pos = value.translation.width
                    let vel = value.predictedEndTranslation.width
                    if pos < -30 || vel < -150 {
                        commit(from: pos, delta: 1)
                    } else if pos > 30 || vel > 150 {
                        commit(from: pos, delta: -1)
                    } else {
                        animOffset = pos
                        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                            animOffset = 0
                        }
                    }
                }
        )
    }

    private func commit(from pos: CGFloat, delta: Int) {
        // Update dot immediately — user sees it move with the swipe
        dotIndex = ((dotIndex + delta) % n + n) % n
        // 1. Freeze current visual position into animOffset before @GestureState zeros
        animOffset = pos
        // 2. Spring to the target card's resting position
        withAnimation(.spring(response: 0.40, dampingFraction: 0.84)) {
            animOffset = -CGFloat(delta) * spacing
        } completion: {
            // 3. After spring settles: swap index + zero offset simultaneously.
            //    Visual positions are identical — zero flash.
            currentIndex = ((currentIndex + delta) % n + n) % n
            animOffset = 0
        }
    }
}

// MARK: - Featured Listing Card

private struct FeaturedListingCard: View {
    let listing: SampleListing
    @Environment(\.colorScheme) private var colorScheme

    private let cardW: CGFloat = 260
    private let cardH: CGFloat = 340
    private let imgH:  CGFloat = 210

    private var categoryIcon: String {
        switch listing.category {
        case "STAYS":       return "house.fill"
        case "FOOD":        return "fork.knife"
        case "JOBS":        return "briefcase.fill"
        case "MARKETPLACE": return "bag.fill"
        default:            return "tag.fill"
        }
    }

    var body: some View {
        let isDark = colorScheme == .dark

        ZStack(alignment: .bottom) {
            // Image / placeholder with gradient overlay
            ZStack(alignment: .bottom) {
                if let urlStr = listing.imageURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill()
                        default: colorPlaceholder
                        }
                    }
                } else {
                    colorPlaceholder
                }

                // Dark scrim for text readability
                LinearGradient(
                    colors: [.clear, .black.opacity(0.15), .black.opacity(0.72)],
                    startPoint: .top, endPoint: .bottom
                )
            }
            .frame(width: cardW, height: cardH)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            // Glass content panel at bottom
            VStack(alignment: .leading, spacing: 8) {
                // Category chip
                HStack(spacing: 5) {
                    Image(systemName: categoryIcon)
                        .font(.system(size: 9, weight: .bold))
                    Text(listing.category)
                        .font(.inter(.bold, size: 9))
                        .tracking(0.8)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(listing.color.opacity(0.85), in: Capsule())

                Text(listing.title)
                    .font(.inter(.bold, size: 14))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .lineSpacing(2)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.7))
                    Text(listing.location)
                        .font(.inter(.medium, size: 11))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                .ultraThinMaterial,
                in: UnevenRoundedRectangle(
                    topLeadingRadius: 0, bottomLeadingRadius: 24,
                    bottomTrailingRadius: 24, topTrailingRadius: 0,
                    style: .continuous
                )
            )
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0, bottomLeadingRadius: 24,
                    bottomTrailingRadius: 24, topTrailingRadius: 0,
                    style: .continuous
                )
                .strokeBorder(.white.opacity(isDark ? 0.12 : 0.3), lineWidth: 0.75)
            )
        }
        .frame(width: cardW, height: cardH)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(isDark ? 0.18 : 0.55), .white.opacity(0.04)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ), lineWidth: 1
                )
        )
    }

    private var colorPlaceholder: some View {
        ZStack {
            listing.color.opacity(colorScheme == .dark ? 0.42 : 0.55)
            Image(systemName: categoryIcon)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.white.opacity(0.30))
        }
    }
}

// MARK: - St. Louis Skyline Illustration

private struct SkylineIllustration: View {
    var fill: Color = .black

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let base = h  // y of ground line

            // ── Helper: draw a building ──────────────────────────────────────
            func building(x: CGFloat, width: CGFloat, height: CGFloat,
                          windows: (cols: Int, rows: Int) = (2, 3)) {
                let bx = x * w
                let bw = width * w
                let bh = height * h
                let by = base - bh
                var p = Path()
                p.addRect(CGRect(x: bx, y: by, width: bw, height: bh))
                ctx.stroke(p, with: .color(fill), lineWidth: 0.8)
                // window grid
                let wcols = windows.cols, wrows = windows.rows
                let ww = bw / CGFloat(wcols + 1) * 0.55
                let wh = bh / CGFloat(wrows + 1) * 0.4
                for col in 1...wcols {
                    for row in 1...wrows {
                        let wx = bx + bw / CGFloat(wcols + 1) * CGFloat(col) - ww / 2
                        let wy = by + bh / CGFloat(wrows + 1) * CGFloat(row) - wh / 2
                        var wp = Path()
                        wp.addRect(CGRect(x: wx, y: wy, width: ww, height: wh))
                        ctx.stroke(wp, with: .color(fill), lineWidth: 0.5)
                    }
                }
            }

            // ── Helper: draw a dome/rounded top building ─────────────────────
            func domeBuilding(x: CGFloat, width: CGFloat, height: CGFloat) {
                let bx = x * w, bw = width * w, bh = height * h, by = base - bh
                var p = Path()
                p.move(to: CGPoint(x: bx, y: base))
                p.addLine(to: CGPoint(x: bx, y: by + bw * 0.3))
                p.addArc(center: CGPoint(x: bx + bw / 2, y: by + bw * 0.3),
                         radius: bw / 2, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                p.addLine(to: CGPoint(x: bx + bw, y: base))
                ctx.stroke(p, with: .color(fill), lineWidth: 0.8)
            }

            // ── Gateway Arch ─────────────────────────────────────────────────
            // Arch is a catenary — approximate with quadratic bezier
            let archLeft  = CGPoint(x: w * 0.72, y: base)
            let archRight = CGPoint(x: w * 0.97, y: base)
            let archPeak  = CGPoint(x: (archLeft.x + archRight.x) / 2, y: base - h * 0.88)

            var arch = Path()
            arch.move(to: archLeft)
            arch.addQuadCurve(to: archRight, control: archPeak)
            ctx.stroke(arch, with: .color(fill), lineWidth: 1.6)

            // Arch legs (slight outward curve at base)
            var legL = Path()
            legL.move(to: archLeft)
            legL.addQuadCurve(
                to: CGPoint(x: archLeft.x + w * 0.015, y: base - h * 0.18),
                control: CGPoint(x: archLeft.x - w * 0.01, y: base - h * 0.08)
            )
            ctx.stroke(legL, with: .color(fill), lineWidth: 2.2)

            var legR = Path()
            legR.move(to: archRight)
            legR.addQuadCurve(
                to: CGPoint(x: archRight.x - w * 0.015, y: base - h * 0.18),
                control: CGPoint(x: archRight.x + w * 0.01, y: base - h * 0.08)
            )
            ctx.stroke(legR, with: .color(fill), lineWidth: 2.2)

            // ── City buildings left-to-right ─────────────────────────────────
            building(x: 0.00, width: 0.028, height: 0.30, windows: (1, 3))
            building(x: 0.03, width: 0.022, height: 0.42, windows: (1, 4))
            building(x: 0.055, width: 0.030, height: 0.35, windows: (1, 3))
            building(x: 0.090, width: 0.025, height: 0.55, windows: (1, 5))   // tall
            building(x: 0.118, width: 0.022, height: 0.28, windows: (1, 2))
            domeBuilding(x: 0.144, width: 0.030, height: 0.38)               // old courthouse dome
            building(x: 0.178, width: 0.028, height: 0.48, windows: (1, 4))
            building(x: 0.210, width: 0.018, height: 0.32, windows: (1, 3))
            building(x: 0.232, width: 0.035, height: 0.62, windows: (2, 5))   // One Metropolitan Square
            building(x: 0.270, width: 0.022, height: 0.38, windows: (1, 3))
            building(x: 0.296, width: 0.028, height: 0.50, windows: (1, 4))
            building(x: 0.328, width: 0.020, height: 0.30, windows: (1, 2))
            building(x: 0.352, width: 0.032, height: 0.44, windows: (1, 4))
            building(x: 0.388, width: 0.022, height: 0.36, windows: (1, 3))
            building(x: 0.414, width: 0.026, height: 0.28, windows: (1, 2))
            building(x: 0.444, width: 0.030, height: 0.46, windows: (1, 4))
            building(x: 0.478, width: 0.020, height: 0.32, windows: (1, 3))
            building(x: 0.502, width: 0.025, height: 0.38, windows: (1, 3))
            building(x: 0.530, width: 0.028, height: 0.26, windows: (1, 2))
            building(x: 0.562, width: 0.022, height: 0.34, windows: (1, 3))
            building(x: 0.588, width: 0.030, height: 0.42, windows: (1, 3))
            building(x: 0.622, width: 0.025, height: 0.22, windows: (1, 2))
            building(x: 0.650, width: 0.028, height: 0.30, windows: (1, 2))
            building(x: 0.682, width: 0.018, height: 0.20, windows: (1, 1))

            // Tree clusters (simple triangles)
            func tree(x: CGFloat, size: CGFloat) {
                let tx = x * w, ts = size * w
                var t = Path()
                t.move(to: CGPoint(x: tx, y: base))
                t.addLine(to: CGPoint(x: tx - ts / 2, y: base - ts * 1.6))
                t.addLine(to: CGPoint(x: tx + ts / 2, y: base - ts * 1.6))
                t.closeSubpath()
                ctx.stroke(t, with: .color(fill), lineWidth: 0.6)
            }
            for i in stride(from: 0.0, through: 0.70, by: 0.04) {
                tree(x: i + 0.01, size: 0.012)
            }

            // Ground line
            var ground = Path()
            ground.move(to: CGPoint(x: 0, y: base))
            ground.addLine(to: CGPoint(x: w, y: base))
            ctx.stroke(ground, with: .color(fill), lineWidth: 0.5)
        }
    }
}


#Preview {
    NavigationStack {
        HomeView(isScrolledDown: .constant(false))
            .environment(AuthService())
            .environment(ThemeManager())
    }
}

#Preview {
    @Previewable @State var scrolled = false
    NavigationStack {
        HomeView(isScrolledDown: $scrolled)
    }
    .environment(AuthService())       // or a mock
    .environment(ThemeManager())
}
