import SwiftUI
import PhotosUI
import UIKit
import Supabase

// MARK: - ClassifiedsView

struct ClassifiedsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ListingsService.self) private var listingsService
    @Environment(AuthService.self) private var auth
    @Environment(AppRouter.self) private var router
    @State private var selectedCategory: ListingCategory = .all
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var showingPostListing = false
    @State private var showSignInPrompt = false
    @FocusState private var isSearchFocused: Bool

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    private var isDark: Bool { colorScheme == .dark }

    private var filteredListings: [Listing] {
        listingsService.listings.filter { listing in
            searchText.isEmpty
                || listing.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Theme.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    marketplaceHeader

                    if showSearch {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Theme.Colors.textSecondary)
                            TextField("Search listings…", text: $searchText)
                                .autocorrectionDisabled()
                                .focused($isSearchFocused)
                            if !searchText.isEmpty {
                                Button { searchText = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Theme.Colors.textLight)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    ScrollView(showsIndicators: false) {
                        if listingsService.isLoading && listingsService.listings.isEmpty {
                            ProgressView()
                                .padding(.top, 60)
                        } else if listingsService.error != nil && listingsService.listings.isEmpty {
                            LoadFailedView {
                                Task { await listingsService.fetchAll(category: selectedCategory.dbValue) }
                            }
                            .padding(.top, 60)
                        } else if filteredListings.isEmpty {
                            EmptyStateView(
                                icon: "bag",
                                title: "No listings yet",
                                message: "Be the first to post in this category."
                            )
                            .padding(.top, 60)
                        } else {
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(filteredListings) { listing in
                                    NavigationLink(destination: ListingDetailView(listing: listing)) {
                                        MarketplaceGridCell(listing: listing)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.top, 14)
                            .padding(.bottom, 100)
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .refreshable { await listingsService.fetchAll(category: selectedCategory.dbValue) }
                }

                // FAB post button
                Button {
                    if auth.currentUser == nil {
                        showSignInPrompt = true
                    } else {
                        showingPostListing = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            LinearGradient(colors: Theme.Colors.primaryGradient,
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: Circle()
                        )
                        .shadow(color: Theme.Colors.primary.opacity(0.28), radius: 18, x: 0, y: 10)
                }
                .padding(.trailing, 22)
                .padding(.bottom, 32)
            }
            .toolbar(.hidden, for: .navigationBar)
            .signInPrompt(isPresented: $showSignInPrompt)
            .sheet(isPresented: $showingPostListing) { PostListingView() }
            .animation(.spring(response: 0.3, dampingFraction: 0.82), value: showSearch)
            .simultaneousGesture(TapGesture().onEnded { isSearchFocused = false })
            .task {
                if let pending = router.pendingListingCategory {
                    selectedCategory = pending
                    router.pendingListingCategory = nil
                }
                await listingsService.fetchAll(category: selectedCategory.dbValue)
            }
            .onChange(of: selectedCategory) { _, newValue in
                Task { await listingsService.fetchAll(category: newValue.dbValue) }
            }
            .onChange(of: router.pendingListingCategory) { _, newValue in
                guard let newValue else { return }
                selectedCategory = newValue
                router.pendingListingCategory = nil
            }
            .onChange(of: showingPostListing) { wasShowing, isShowing in
                if wasShowing && !isShowing {
                    Task { await listingsService.fetchAll(category: selectedCategory.dbValue) }
                }
            }
        }
    }

    // MARK: Header

    private var marketplaceHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text("Classifieds")
                    .font(.nunito(.black, size: 28))
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        showSearch.toggle()
                        if !showSearch { searchText = "" }
                    }
                    if showSearch {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            isSearchFocused = true
                        }
                    } else {
                        isSearchFocused = false
                    }
                } label: {
                    Image(systemName: showSearch ? "xmark" : "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(.white.opacity(0.16), in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.28), lineWidth: 1))
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
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
        .padding(.bottom, 14)
        .background {
            Group {
                if isDark {
                    LinearGradient(
                        stops: [.init(color: Color(hex: "#171717"), location: 0),
                                .init(color: Color(hex: "#2B2B2B"), location: 1)],
                        startPoint: .bottom, endPoint: .top
                    )
                } else {
                    Color(hex: "#0A2463")
                }
            }
            .ignoresSafeArea(edges: .top)
        }
    }
}

// MARK: - Grid Cell

private struct MarketplaceGridCell: View {
    let listing: Listing
    @Environment(\.colorScheme) private var colorScheme

    private var kind: ListingCategoryKind { listing.categoryEnum }
    private var kindColors: [Color] { kind.gradientColors.map { Color(hex: $0) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let first = listing.images.first, let url = URL(string: first) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                            default:
                                gradientPlaceholder
                            }
                        }
                    } else {
                        gradientPlaceholder
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 130)
                .clipped()

                Text(listing.formattedPrice ?? "—")
                    .font(.inter(.bold, size: 13))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.58), in: RoundedRectangle(cornerRadius: 6))
                    .padding(8)
            }
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12,
                                              style: .continuous))

            Text(listing.title)
                .font(.inter(.semibold, size: 13))
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.card)
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 12, bottomTrailingRadius: 12,
                                                  style: .continuous))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.28 : 0.08), radius: 6, x: 0, y: 2)
    }

    private var gradientPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: kindColors.map { $0.opacity(0.88) },
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Image(systemName: kind.icon)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))
        }
    }
}

// MARK: - Category Filter Chip

struct CategoryFilterChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let selectedColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage).font(.system(size: 11, weight: .bold))
                Text(title).font(Theme.Fonts.nunitoBold(size: 12)).lineLimit(1)
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.78))
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background {
                if isSelected {
                    LinearGradient(colors: selectedColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        .clipShape(Capsule())
                } else {
                    Capsule().fill(.white.opacity(0.14))
                        .overlay(Capsule().stroke(.white.opacity(0.30), lineWidth: 1))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Listing Detail

struct ListingDetailView: View {
    let listing: Listing
    @Environment(AuthService.self) private var auth
    @Environment(MessagesService.self) private var messagesService
    @State private var chatConversation: Conversation?
    @State private var isStartingChat = false
    @State private var showSignInPrompt = false
    @State private var showReport = false

    private var kind: ListingCategoryKind { listing.categoryEnum }
    private var kindColors: [Color] { kind.gradientColors.map { Color(hex: $0) } }
    private var isMine: Bool { listing.userId == auth.currentUser?.id }

    private var postedRelative: String {
        RelativeDateTimeFormatter().localizedString(for: listing.createdAt, relativeTo: Date())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header artwork
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(colors: kindColors,
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: kind.icon)
                        .font(.system(size: 72, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.22))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 30)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(kind.displayName.uppercased())
                            .font(.inter(.bold, size: 11))
                            .tracking(1)
                            .foregroundStyle(.white.opacity(0.75))
                        Text(listing.formattedPrice ?? "Price on request")
                            .font(.inter(.heavy, size: 28))
                            .foregroundStyle(.white)
                        Text(listing.title)
                            .font(.inter(.semibold, size: 16))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(20)
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(Theme.Fonts.nunitoExtraBold(size: 20))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(listing.description)
                        .font(Theme.Fonts.interRegular(size: 15))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineSpacing(5)
                    Divider()
                    if let location = listing.metadata?.location {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(Theme.Fonts.interMedium(size: 14))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    Label("Posted \(postedRelative)", systemImage: "clock")
                        .font(Theme.Fonts.interMedium(size: 14))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(20)
                .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, Theme.Spacing.lg)

                if !isMine {
                    PrimaryButton("Message Seller", isLoading: isStartingChat) {
                        if auth.currentUser == nil {
                            showSignInPrompt = true
                        } else {
                            Task { await startChat() }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, 30)
                }
            }
        }
        .background(Theme.Colors.background)
        .navigationTitle(listing.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ShareLink(item: shareText) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    if !isMine {
                        Button(role: .destructive) {
                            if auth.currentUser == nil {
                                showSignInPrompt = true
                            } else {
                                showReport = true
                            }
                        } label: {
                            Label("Report", systemImage: "flag")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .signInPrompt(isPresented: $showSignInPrompt)
        .sheet(isPresented: $showReport) {
            if let myId = auth.currentUser?.id {
                ReportSheet(reporterId: myId, reportedUserId: listing.userId, listingId: listing.id)
            }
        }
        .navigationDestination(item: $chatConversation) { conversation in
            if let myId = auth.currentUser?.id {
                ChatView(conversation: conversation, myId: myId)
            }
        }
    }

    private var shareText: String {
        var text = "\(listing.title) on Milao"
        if let price = listing.formattedPrice { text += " — \(price)" }
        if let location = listing.metadata?.location { text += " · \(location)" }
        return text
    }

    private func startChat() async {
        guard let myId = auth.currentUser?.id else { return }
        isStartingChat = true
        defer { isStartingChat = false }
        chatConversation = try? await messagesService.getOrCreate(
            myId: myId, otherUserId: listing.userId,
            listingId: listing.id, listingTitle: listing.title
        )
    }
}

// MARK: - Post Listing

enum PostCategory: String, CaseIterable, Identifiable {
    case accommodations = "Accommodations"
    case jobs           = "Jobs"
    case buySell        = "Buy & Sell"
    case food           = "Food"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .accommodations: "bed.double.fill"
        case .jobs:           "briefcase.fill"
        case .buySell:        "bag.fill"
        case .food:           "fork.knife"
        }
    }

    var colors: [Color] {
        switch self {
        case .accommodations: [Color(hex: "F0883E"), Color(hex: "D4691E")]
        case .jobs:           [Color(hex: "00C48C"), Color(hex: "007A5E")]
        case .buySell:        [Color(hex: "0099FF"), Color(hex: "0055CC")]
        case .food:           [Theme.Colors.primary, Color(hex: "E68A00")]
        }
    }
}

struct PostListingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ListingsService.self) private var listingsService
    @Environment(AuthService.self) private var auth

    @State private var selectedCategory: PostCategory? = nil
    @State private var showSuccess = false
    @State private var isPosting = false
    @State private var postFailed = false

    // Shared
    @State private var title = ""
    @State private var description = ""
    @State private var locationText = ""
    @State private var pickedPhotos: [PhotosPickerItem] = []
    @State private var pickedImages: [UIImage] = []
    @State private var showCamera = false
    @State private var cameraImage: UIImage? = nil

    // Accommodations
    @State private var rent = ""
    @State private var bedrooms = "1"
    @State private var bathrooms = "1"

    // Jobs
    @State private var company = ""
    @State private var salary = ""
    @State private var jobType = "Full-time"
    @State private var applyContact = ""
    let jobTypes = ["Full-time", "Part-time", "Contract", "Internship"]

    // Buy & Sell
    @State private var price = ""
    @State private var condition = "Good"
    let conditions = ["New", "Like New", "Good", "Fair"]

    // Food
    @State private var foodPrice = ""
    @State private var businessName = ""
    @State private var pickupTime = ""
    @State private var allergens = ""

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        categoryPicker

                        if selectedCategory != nil {
                            photoSection
                                .transition(.move(edge: .top).combined(with: .opacity))
                            categoryFields
                                .transition(.move(edge: .top).combined(with: .opacity))
                            postButton
                                .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    .animation(.spring(response: 0.38, dampingFraction: 0.82), value: selectedCategory)
                }
                .scrollDismissesKeyboard(.interactively)

                if showSuccess {
                    PostSuccessOverlay {
                        dismiss()
                    }
                    .transition(.opacity)
                }
            }
            .navigationTitle("Post a Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { hideKeyboard() }
                        .font(.inter(.semibold, size: 15))
                }
            }
            .alert("Couldn't post your listing", isPresented: $postFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please check your connection and try again — your form is still filled in.")
            }
            .sheet(isPresented: $showCamera) {
                CameraPickerView { img in
                    if let img { pickedImages.append(img) }
                }
            }
            .onChange(of: pickedPhotos) {
                Task {
                    for item in pickedPhotos {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let img = UIImage(data: data) {
                            pickedImages.append(img)
                        }
                    }
                    pickedPhotos = []
                }
            }
        }
    }

    // MARK: Category Picker

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What are you posting?")
                .font(.inter(.bold, size: 16))
                .foregroundStyle(Theme.Colors.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(PostCategory.allCases) { cat in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                            selectedCategory = selectedCategory == cat ? nil : cat
                        }
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(selectedCategory == cat
                                          ? LinearGradient(colors: cat.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                          : LinearGradient(colors: [Theme.Colors.card, Theme.Colors.card], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 36, height: 36)
                                Image(systemName: cat.icon)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(selectedCategory == cat ? .white : Theme.Colors.textSecondary)
                            }
                            Text(cat.rawValue)
                                .font(.inter(.semibold, size: 14))
                                .foregroundStyle(selectedCategory == cat ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Theme.Colors.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(selectedCategory == cat
                                                ? cat.colors.first ?? Theme.Colors.primary
                                                : Theme.Colors.border, lineWidth: selectedCategory == cat ? 2 : 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Photo Section

    @ViewBuilder
    private var photoSection: some View {
        if selectedCategory != .jobs {
            VStack(alignment: .leading, spacing: 12) {
                Text("Photos")
                    .font(.inter(.bold, size: 16))
                    .foregroundStyle(Theme.Colors.textPrimary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // Camera button
                        Button { showCamera = true } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(Theme.Colors.textSecondary)
                                Text("Camera")
                                    .font(.inter(.medium, size: 11))
                                    .foregroundStyle(Theme.Colors.textLight)
                            }
                            .frame(width: 80, height: 80)
                            .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.Colors.border, style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                            )
                        }
                        .buttonStyle(.plain)

                        // Library picker
                        PhotosPicker(selection: $pickedPhotos, maxSelectionCount: 8,
                                     matching: .images) {
                            VStack(spacing: 6) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 22))
                                    .foregroundStyle(Theme.Colors.textSecondary)
                                Text("Library")
                                    .font(.inter(.medium, size: 11))
                                    .foregroundStyle(Theme.Colors.textLight)
                            }
                            .frame(width: 80, height: 80)
                            .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.Colors.border, style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                            )
                        }

                        // Picked images
                        ForEach(pickedImages.indices, id: \.self) { i in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: pickedImages[i])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                Button {
                                    _ = pickedImages.remove(at: i)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.white)
                                        .background(Circle().fill(.black.opacity(0.55)))
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    // MARK: Category-specific Fields

    @ViewBuilder
    private var categoryFields: some View {
        if let cat = selectedCategory {
            VStack(spacing: 16) {
                switch cat {
                case .accommodations: accommodationsFields
                case .jobs:           jobsFields
                case .buySell:        buySellFields
                case .food:           foodFields
                }
            }
        }
    }

    private var accommodationsFields: some View {
        VStack(spacing: 14) {
            fieldSection("Listing Title", placeholder: "e.g. 2BR near WashU, utilities incl.", text: $title)
            fieldSection("Monthly Rent", placeholder: "e.g. 1,200", text: $rent, keyboardType: .numberPad)
            HStack(spacing: 12) {
                pickerField("Bedrooms", value: $bedrooms,
                            options: ["Studio", "1", "2", "3", "4+"])
                pickerField("Bathrooms", value: $bathrooms,
                            options: ["1", "1.5", "2", "2.5", "3+"])
            }
            fieldSection("Neighborhood / Address", placeholder: "University City, MO", text: $locationText)
            fieldSection("Description", placeholder: "Describe the space, amenities, lease terms…", text: $description, axis: .vertical, minHeight: 100)
        }
    }

    private var jobsFields: some View {
        VStack(spacing: 14) {
            fieldSection("Job Title", placeholder: "e.g. Software Engineer", text: $title)
            fieldSection("Company / Employer", placeholder: "Company name", text: $company)
            pickerField("Employment Type", value: $jobType, options: jobTypes)
            fieldSection("Salary / Pay Rate", placeholder: "e.g. $80k–$100k or $25/hr (optional)", text: $salary)
            fieldSection("Location", placeholder: "e.g. Clayton, MO or Remote", text: $locationText)
            fieldSection("Job Description & Requirements",
                         placeholder: "Role overview, required skills, qualifications…",
                         text: $description, axis: .vertical, minHeight: 120)
            fieldSection("How to Apply", placeholder: "Email or link to apply", text: $applyContact, keyboardType: .URL)
        }
    }

    private var buySellFields: some View {
        VStack(spacing: 14) {
            fieldSection("Item Name", placeholder: "e.g. MacBook Air M2", text: $title)
            fieldSection("Price", placeholder: "e.g. 650", text: $price, keyboardType: .decimalPad)
            pickerField("Condition", value: $condition, options: conditions)
            fieldSection("Pickup Location", placeholder: "e.g. Clayton, MO", text: $locationText)
            fieldSection("Description", placeholder: "Describe the item, any defects, what's included…",
                         text: $description, axis: .vertical, minHeight: 90)
        }
    }

    private var foodFields: some View {
        VStack(spacing: 14) {
            fieldSection("Dish / Item Name", placeholder: "e.g. Hyderabadi Biryani Trays", text: $title)
            HStack(spacing: 12) {
                fieldSection("Price", placeholder: "e.g. $42", text: $foodPrice, keyboardType: .decimalPad)
                fieldSection("Seller / Business", placeholder: "Your name", text: $businessName)
            }
            fieldSection("Pickup Location", placeholder: "Street or neighborhood", text: $locationText)
            fieldSection("Available Date & Time", placeholder: "e.g. Friday 6–8 PM", text: $pickupTime)
            fieldSection("Allergens (optional)", placeholder: "e.g. Contains nuts, gluten-free", text: $allergens)
            fieldSection("Description", placeholder: "Tell buyers what makes it special…",
                         text: $description, axis: .vertical, minHeight: 80)
        }
    }

    // MARK: Post Button

    private var postButton: some View {
        Button {
            Task { await submitListing() }
        } label: {
            Group {
                if isPosting {
                    ProgressView().tint(.white)
                } else {
                    Text("Post Listing")
                        .font(.inter(.bold, size: 16))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(colors: Theme.Colors.primaryGradient,
                               startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isPosting)
        .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
    }

    // MARK: Submit

    private func submitListing() async {
        guard let cat = selectedCategory, let userId = auth.currentUser?.id else { return }
        isPosting = true
        defer { isPosting = false }

        var uploadedURLs: [String] = []
        for image in pickedImages {
            if let data = image.jpegData(compressionQuality: 0.8),
               let url = try? await listingsService.uploadImage(data) {
                uploadedURLs.append(url)
            }
        }

        let dbCategory: String
        var metadata: [String: AnyJSON] = [:]
        var priceValue: Double?
        var fullDescription = description

        switch cat {
        case .accommodations:
            dbCategory = "accommodation"
            priceValue = Double(rent.filter { $0.isNumber || $0 == "." })
            if let beds = Int(bedrooms) { metadata["bedrooms"] = .double(Double(beds)) }
            if let baths = Double(bathrooms) { metadata["bathrooms"] = .double(baths) }
            if !locationText.isEmpty { metadata["location"] = .string(locationText) }
        case .jobs:
            dbCategory = "jobs"
            if !company.isEmpty { metadata["company"] = .string(company) }
            if !salary.isEmpty { metadata["salary_range"] = .string(salary) }
            if !locationText.isEmpty { metadata["location"] = .string(locationText) }
            fullDescription += "\n\nType: \(jobType)"
            if !applyContact.isEmpty { fullDescription += "\nApply: \(applyContact)" }
        case .buySell:
            dbCategory = "buysell"
            priceValue = Double(price.filter { $0.isNumber || $0 == "." })
            metadata["condition"] = .string(condition)
            if !locationText.isEmpty { metadata["location"] = .string(locationText) }
        case .food:
            dbCategory = "food"
            priceValue = Double(foodPrice.filter { $0.isNumber || $0 == "." })
            if !businessName.isEmpty { metadata["business_name"] = .string(businessName) }
            if !allergens.isEmpty { metadata["allergens"] = .string(allergens) }
            if !locationText.isEmpty { metadata["location"] = .string(locationText) }
            if !pickupTime.isEmpty { fullDescription += "\n\nAvailable: \(pickupTime)" }
        }

        do {
            _ = try await listingsService.post(
                userId: userId,
                title: title,
                description: fullDescription,
                category: dbCategory,
                price: priceValue,
                images: uploadedURLs,
                metadata: metadata
            )
            withAnimation(.easeIn(duration: 0.18)) { showSuccess = true }
        } catch {
            // Leave the form as-is so the user can retry.
            postFailed = true
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: Field Helpers

    private func fieldSection(_ label: String, placeholder: String, text: Binding<String>,
                               axis: Axis = .horizontal, minHeight: CGFloat? = nil,
                               keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.inter(.medium, size: 13))
                .foregroundStyle(Theme.Colors.textSecondary)
            TextField(placeholder, text: text, axis: axis)
                .font(.inter(.regular, size: 15))
                .foregroundStyle(Theme.Colors.textPrimary)
                .keyboardType(keyboardType)
                .autocorrectionDisabled(keyboardType == .URL)
                .padding(12)
                .frame(minHeight: minHeight)
                .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
        }
    }

    private func pickerField(_ label: String, value: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.inter(.medium, size: 13))
                .foregroundStyle(Theme.Colors.textSecondary)
            Menu {
                ForEach(options, id: \.self) { opt in
                    Button(opt) { value.wrappedValue = opt }
                }
            } label: {
                HStack {
                    Text(value.wrappedValue)
                        .font(.inter(.regular, size: 15))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textLight)
                }
                .padding(12)
                .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Post Success Overlay

private struct PostSuccessOverlay: View {
    let onDone: () -> Void
    @State private var ringProgress: CGFloat = 0
    @State private var checkProgress: CGFloat = 0
    @State private var textOpacity: CGFloat = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture {}

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.2), lineWidth: 5)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    Path { p in
                        p.move(to:    CGPoint(x: 28, y: 52))
                        p.addLine(to: CGPoint(x: 44, y: 68))
                        p.addLine(to: CGPoint(x: 74, y: 36))
                    }
                    .trim(from: 0, to: checkProgress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    .frame(width: 100, height: 100)
                }

                VStack(spacing: 8) {
                    Text("Ad Posted!")
                        .font(.inter(.heavy, size: 22))
                        .foregroundStyle(.white)
                    Text("Your listing will be live\nin a few minutes.")
                        .font(.inter(.regular, size: 15))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                }
                .opacity(textOpacity)

                Button {
                    onDone()
                } label: {
                    Text("Done")
                        .font(.inter(.bold, size: 16))
                        .foregroundStyle(.white)
                        .frame(width: 140, height: 46)
                        .background(Color.green, in: RoundedRectangle(cornerRadius: 14))
                }
                .opacity(textOpacity)
            }
            .padding(36)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(.white.opacity(0.14), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 40)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { ringProgress = 1 }
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) { checkProgress = 1 }
            withAnimation(.easeOut(duration: 0.4).delay(0.9)) { textOpacity = 1 }
        }
    }
}

// MARK: - Camera Picker

private struct CameraPickerView: UIViewControllerRepresentable {
    let onImage: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImage: (UIImage?) -> Void
        init(onImage: @escaping (UIImage?) -> Void) { self.onImage = onImage }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            onImage(info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            onImage(nil)
        }
    }
}

// MARK: - Edit Listing

struct EditListingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ListingsService.self) private var listingsService
    let listing: Listing
    @State private var title: String
    @State private var description: String
    @State private var isSaving = false

    init(listing: Listing) {
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(isSaving)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        try? await listingsService.update(id: listing.id, updates: [
            "title": .string(title),
            "description": .string(description),
        ])
        isSaving = false
        dismiss()
    }
}
