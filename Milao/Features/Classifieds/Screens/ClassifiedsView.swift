import SwiftUI

struct ClassifiedsView: View {
    @State private var selectedCategory: ListingCategory = .all
    @State private var searchText = ""
    @State private var showingPostListing = false

    private var filteredListings: [CommunityListing] {
        CommunitySamples.listings.filter { listing in
            let matchesCategory = selectedCategory == .all || listing.category == selectedCategory
            let matchesSearch = searchText.isEmpty || listing.title.localizedCaseInsensitiveContains(searchText) || listing.description.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Theme.Colors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        marketplaceHeader

                        LazyVStack(spacing: 18) {
                            ForEach(filteredListings) { listing in
                                NavigationLink(destination: ListingDetailView(listing: listing)) {
                                    MarketplaceListingCard(listing: listing)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 120)
                    }
                }

                Button {
                    showingPostListing = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(width: 62, height: 62)
                        .background(
                            LinearGradient(colors: Theme.Colors.primaryGradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: Circle()
                        )
                        .shadow(color: Theme.Colors.primary.opacity(0.28), radius: 18, x: 0, y: 10)
                }
                .padding(.trailing, 22)
                .padding(.bottom, 112)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingPostListing) {
                PostListingView()
            }
        }
    }

    private var marketplaceHeader: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .center) {
                Text("Marketplace")
                    .font(Theme.Fonts.nunitoExtraBold(size: 30))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                Button { } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(width: 52, height: 52)
                        .background(Theme.Colors.white.opacity(0.28), in: Circle())
                        .overlay(Circle().stroke(Theme.Colors.white.opacity(0.38), lineWidth: 1))
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, 50)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ListingCategory.allCases) { category in
                        CategoryFilterChip(
                            title: category.rawValue,
                            systemImage: category.icon,
                            isSelected: selectedCategory == category,
                            selectedColors: category == .all ? Theme.Colors.primaryGradient : category.colors
                        ) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.86)) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
        }
        .padding(.bottom, 22)
        .background(
            LinearGradient(colors: Theme.Colors.headerGradientLight, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)
        )
    }
}

private struct MarketplaceListingCard: View {
    let listing: CommunityListing

    private var priceText: String {
        listing.price
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                listingArtwork
                    .frame(height: 162)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))

                LinearGradient(colors: [.black.opacity(0.44), .clear], startPoint: .bottom, endPoint: .top)

                VStack(alignment: .leading, spacing: 0) {
                    if listing.isFeatured {
                        Text("★ Featured")
                            .font(Theme.Fonts.nunitoBold(size: 14))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(colors: Theme.Colors.primaryGradient, startPoint: .leading, endPoint: .trailing),
                                in: Capsule()
                            )
                            .padding(.bottom, 58)
                    }

                    Text(priceText)
                        .font(Theme.Fonts.nunitoExtraBold(size: 22))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.58), in: Capsule())
                }
                .padding(18)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(listing.title)
                    .font(Theme.Fonts.nunitoExtraBold(size: 20))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)

                Text(listing.description)
                    .font(Theme.Fonts.interRegular(size: 15))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineSpacing(4)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                    Text(listing.location)
                    Spacer(minLength: 8)
                    Text("·")
                    Text(listing.posted)
                }
                .font(Theme.Fonts.interRegular(size: 15))
                .foregroundStyle(Theme.Colors.textLight)
            }
            .padding(18)
            .background(Theme.Colors.card)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 18, x: 0, y: 8)
    }

    private var listingArtwork: some View {
        ZStack {
            LinearGradient(colors: listing.category.colors.map { $0.opacity(0.92) }, startPoint: .topLeading, endPoint: .bottomTrailing)
            GeometryReader { proxy in
                Circle()
                    .fill(.white.opacity(0.16))
                    .frame(width: proxy.size.width * 0.62)
                    .offset(x: proxy.size.width * 0.48, y: -proxy.size.height * 0.18)
                Circle()
                    .fill(.black.opacity(0.09))
                    .frame(width: proxy.size.width * 0.5)
                    .offset(x: -proxy.size.width * 0.18, y: proxy.size.height * 0.48)
            }
            Image(systemName: listing.category.icon)
                .font(.system(size: 66, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
        }
    }
}

struct CategoryFilterChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let selectedColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(Theme.Fonts.nunitoBold(size: 15))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? .white : Theme.Colors.textSecondary)
            .padding(.horizontal, 15)
            .frame(height: 44)
            .background {
                if isSelected {
                    LinearGradient(colors: selectedColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        .clipShape(Capsule())
                } else {
                    Capsule()
                        .fill(.regularMaterial)
                        .overlay(Capsule().stroke(Theme.Colors.white.opacity(0.55), lineWidth: 1))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct ListingDetailView: View {
    let listing: CommunityListing
    @State private var showingChat = false
    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                MarketplaceListingCard(listing: listing)
                    .padding(.top, 16)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(Theme.Fonts.nunitoExtraBold(size: 24))
                    Text(listing.description)
                        .font(Theme.Fonts.interRegular(size: 17))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineSpacing(5)
                    Label(listing.location, systemImage: "mappin.and.ellipse")
                        .font(Theme.Fonts.interMedium(size: 16))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(20)
                .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(spacing: 12) {
                    PrimaryButton("Message Seller") { showingChat = true }
                    Button("Edit Listing") { showingEdit = true }
                        .buttonStyle(.bordered)
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
        .navigationTitle(listing.category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingChat) {
            ChatView(conversation: CommunityConversation(name: listing.seller, subject: listing.title, preview: "Hi, is this still available?", timestamp: "now", tint: listing.category.colors.first ?? Theme.Colors.primary))
        }
        .sheet(isPresented: $showingEdit) {
            EditListingView(listing: listing)
        }
    }
}

struct PostListingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var price = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Description", text: $description, axis: .vertical)
                TextField("Price", text: $price)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("New Listing")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Post") { dismiss() } }
            }
        }
    }
}

struct EditListingView: View {
    @Environment(\.dismiss) private var dismiss
    let listing: CommunityListing
    @State private var title: String
    @State private var description: String

    init(listing: CommunityListing) {
        self.listing = listing
        _title = State(initialValue: listing.title)
        _description = State(initialValue: listing.description)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Description", text: $description, axis: .vertical)
            }
            .navigationTitle("Edit Listing")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { dismiss() } }
            }
        }
    }
}
