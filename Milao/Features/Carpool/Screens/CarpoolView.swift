import SwiftUI
import UIKit
import Supabase
import CoreLocation

struct CarpoolView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(RidesService.self) private var ridesService
    @Environment(AuthService.self) private var auth
    @State private var selectedCategory: RideCategory = .all
    @State private var showingPostRide = false
    @State private var showSignInPrompt = false
    @State private var searchText = ""
    @State private var showSearch = false
    @FocusState private var isSearchFocused: Bool

    private var isDark: Bool { colorScheme == .dark }

    private var filteredRides: [Ride] {
        ridesService.rides.filter { ride in
            searchText.isEmpty
                || ride.fromLocation.localizedCaseInsensitiveContains(searchText)
                || ride.toLocation.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var offeringCount: Int { filteredRides.filter { $0.isOffering }.count }
    private var requestingCount: Int { filteredRides.filter { !$0.isOffering }.count }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Theme.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    carpoolHeader

                    if showSearch {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Theme.Colors.textSecondary)
                            TextField("Search by location…", text: $searchText)
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
                        VStack(spacing: 0) {
                            HStack(spacing: 10) {
                                StatPill(title: "\(offeringCount) offering", icon: "car.fill", color: Theme.Colors.info)
                                StatPill(title: "\(requestingCount) requesting", icon: "hand.raised.fill", color: Theme.Colors.warning)
                                Spacer()
                            }
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.top, 14)
                            .padding(.bottom, 10)

                            if ridesService.isLoading && ridesService.rides.isEmpty {
                                ProgressView().padding(.top, 60)
                            } else if ridesService.error != nil && ridesService.rides.isEmpty {
                                LoadFailedView {
                                    Task { await ridesService.fetchAll(category: selectedCategory.dbValue) }
                                }
                                .padding(.top, 60)
                            } else if filteredRides.isEmpty {
                                EmptyStateView(
                                    icon: "car",
                                    title: "No rides yet",
                                    message: "Be the first to offer or request a ride."
                                )
                                .padding(.top, 60)
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(filteredRides) { ride in
                                        NavigationLink(destination: RideDetailView(ride: ride)) {
                                            RideRouteCard(ride: ride)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.lg)
                                .padding(.bottom, 100)
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .refreshable { await ridesService.fetchAll(category: selectedCategory.dbValue) }
                }

                Button {
                    if auth.currentUser == nil {
                        showSignInPrompt = true
                    } else {
                        showingPostRide = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            LinearGradient(colors: Theme.Colors.primaryGradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: Circle()
                        )
                        .shadow(color: Theme.Colors.primary.opacity(0.28), radius: 18, x: 0, y: 10)
                }
                .padding(.trailing, 22)
                .padding(.bottom, 32)
            }
            .toolbar(.hidden, for: .navigationBar)
            .signInPrompt(isPresented: $showSignInPrompt)
            .sheet(isPresented: $showingPostRide) {
                PostRideView()
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.82), value: showSearch)
            .simultaneousGesture(TapGesture().onEnded { isSearchFocused = false })
            .task { await ridesService.fetchAll(category: selectedCategory.dbValue) }
            .onChange(of: selectedCategory) { _, newValue in
                Task { await ridesService.fetchAll(category: newValue.dbValue) }
            }
            .onChange(of: showingPostRide) { wasShowing, isShowing in
                if wasShowing && !isShowing {
                    Task { await ridesService.fetchAll(category: selectedCategory.dbValue) }
                }
            }
        }
    }

    private func categoryAccent(_ category: RideCategory) -> Color {
        switch category {
        case .all: Theme.Colors.primary
        case .airport: Theme.Colors.info
        case .university: Theme.Colors.secondary
        case .religious: Theme.Colors.success
        case .general: Theme.Colors.carpoolAccent
        case .longRide: Theme.Colors.warning
        }
    }

    private var carpoolHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Carpool")
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
                    ForEach(RideCategory.allCases) { category in
                        CategoryFilterChip(
                            title: category.rawValue,
                            systemImage: category.icon,
                            isSelected: selectedCategory == category,
                            selectedColors: category == .all ? Theme.Colors.primaryGradient : [categoryAccent(category), categoryAccent(category).opacity(0.78)]
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
                        stops: [
                            .init(color: Color(hex: "#171717"), location: 0),
                            .init(color: Color(hex: "#2B2B2B"), location: 1),
                        ],
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

private struct StatPill: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(Theme.Fonts.nunitoBold(size: 11))
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(color.opacity(0.11), in: Capsule())
    }
}

private struct RideRouteCard: View {
    let ride: Ride

    private var accent: Color { ride.isOffering ? Color(hex: "0099FF") : Theme.Colors.primary }
    private var badgeTitle: String { ride.isOffering ? "Offering" : "Need Seat" }
    private var badgeIcon: String { ride.isOffering ? "car.fill" : "hand.raised.fill" }
    private var seatText: String {
        let seats = ride.seatsAvailable ?? 0
        return ride.isOffering ? "\(seats) seats" : "\(seats) needed"
    }
    private var dateText: String {
        guard let d = ride.rideDate else { return "TBD" }
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none
        return f.string(from: d)
    }
    private var timeText: String {
        guard let d = ride.rideDate else { return "" }
        let f = DateFormatter(); f.dateStyle = .none; f.timeStyle = .short
        return f.string(from: d)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                HStack(spacing: 4) {
                    Image(systemName: badgeIcon)
                    Text(badgeTitle)
                }
                .font(Theme.Fonts.nunitoBold(size: 11))
                .foregroundStyle(accent)
                .padding(.horizontal, 8)
                .frame(height: 28)
                .background(accent.opacity(0.1), in: Capsule())
                .overlay(Capsule().stroke(accent.opacity(0.24), lineWidth: 1))

                Spacer()

                if ride.category != nil {
                    Text(ride.categoryKind.displayName)
                        .font(Theme.Fonts.nunitoBold(size: 11))
                        .foregroundStyle(Theme.Colors.textLight)
                }
            }

            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 4) {
                    Circle().fill(accent).frame(width: 8, height: 8)
                    Rectangle().fill(accent.opacity(0.22)).frame(width: 2, height: 18)
                    Circle().stroke(accent, lineWidth: 2.5).frame(width: 8, height: 8)
                }
                .padding(.top, 4)

                VStack(alignment: .leading, spacing: 12) {
                    Text(ride.fromLocation)
                    Text(ride.toLocation)
                }
                .font(Theme.Fonts.nunitoExtraBold(size: 14))
                .foregroundStyle(Theme.Colors.textPrimary)
            }
            .padding(.leading, 4)

            HStack(spacing: 6) {
                RideMetaPill(text: dateText, icon: "calendar", color: accent)
                if !timeText.isEmpty { RideMetaPill(text: timeText, icon: "clock", color: accent) }
                RideMetaPill(text: seatText, icon: "person.2", color: accent)
            }
        }
        .padding(13)
        .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .top) {
            Capsule()
                .fill(accent)
                .frame(height: 3)
                .padding(.horizontal, 18)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 3)
    }
}

private struct RideMetaPill: View {
    let text: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(Theme.Fonts.nunitoBold(size: 11))
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .frame(height: 26)
        .background(color.opacity(0.1), in: Capsule())
    }
}

struct RideDetailView: View {
    let ride: Ride
    @Environment(AuthService.self) private var auth
    @Environment(MessagesService.self) private var messagesService
    @State private var chatConversation: Conversation?
    @State private var isStartingChat = false
    @State private var showingEdit = false
    @State private var showSignInPrompt = false
    @State private var showReport = false

    private var isMine: Bool { ride.ownerId == auth.currentUser?.id }

    private var shareText: String {
        let verb = ride.isOffering ? "Ride offer" : "Ride request"
        return "\(verb) on Milao: \(ride.fromLocation) → \(ride.toLocation)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RideRouteCard(ride: ride)
                    .padding(.top, 16)

                if let fromCoordinate = ride.fromCoordinate, let toCoordinate = ride.toCoordinate {
                    RideRoutePreview(
                        fromCoordinate: fromCoordinate,
                        toCoordinate: toCoordinate,
                        fromLabel: ride.fromLocation,
                        toLabel: ride.toLocation
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Trip Details")
                        .font(Theme.Fonts.nunitoExtraBold(size: 24))
                    if let notes = ride.notes, !notes.isEmpty {
                        Text(notes)
                            .font(Theme.Fonts.interRegular(size: 17))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    Label(ride.categoryKind.displayName, systemImage: ride.categoryKind.icon)
                        .font(Theme.Fonts.interMedium(size: 16))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                if isMine {
                    Button("Edit Ride") { showingEdit = true }
                        .buttonStyle(.glass)
                } else {
                    PrimaryButton(ride.isOffering ? "Request Seat" : "Offer Ride", isLoading: isStartingChat) {
                        if auth.currentUser == nil {
                            showSignInPrompt = true
                        } else {
                            Task { await startChat() }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Ride")
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
                ReportSheet(reporterId: myId, reportedUserId: ride.ownerId, rideId: ride.id)
            }
        }
        .navigationDestination(item: $chatConversation) { conversation in
            if let myId = auth.currentUser?.id {
                ChatView(conversation: conversation, myId: myId)
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditRideView(ride: ride)
        }
    }

    private func startChat() async {
        guard let myId = auth.currentUser?.id, let otherId = ride.ownerId else { return }
        isStartingChat = true
        defer { isStartingChat = false }
        chatConversation = try? await messagesService.getOrCreate(myId: myId, otherUserId: otherId, rideId: ride.id)
    }
}

struct PostRideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RidesService.self) private var ridesService
    @Environment(AuthService.self) private var auth
    @State private var rideType = "offer"
    @State private var from = ""
    @State private var to = ""
    @State private var fromCoordinate: CLLocationCoordinate2D?
    @State private var toCoordinate: CLLocationCoordinate2D?
    @State private var rideDate = Date()
    @State private var seats = 1
    @State private var category: RideCategoryKind = .general
    @State private var notes = ""
    @State private var isPosting = false
    @State private var showSuccess = false
    @State private var postFailed = false

    private var isOffering: Bool { rideType == "offer" }
    private var typeAccent: Color { isOffering ? Color(hex: "0099FF") : Theme.Colors.primary }

    private var canPost: Bool {
        !from.trimmingCharacters(in: .whitespaces).isEmpty &&
        !to.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        rideTypeSection
                        routeSection
                        dateAndSeatsSection
                        categorySection
                        notesSection
                        postButton
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)

                if showSuccess {
                    RidePostSuccessOverlay { dismiss() }
                        .transition(.opacity)
                }
            }
            .alert("Couldn't post your ride", isPresented: $postFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please check your connection and try again — your form is still filled in.")
            }
            .navigationTitle("Post a Ride")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { hideKeyboard() }
                        .font(.inter(.semibold, size: 15))
                }
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: Ride Type

    private var rideTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What do you need?")
                .font(.inter(.bold, size: 16))
                .foregroundStyle(Theme.Colors.textPrimary)

            HStack(spacing: 10) {
                rideTypeCard(
                    title: "Offering a Ride",
                    subtitle: "You're driving",
                    icon: "car.fill",
                    accent: Color(hex: "0099FF"),
                    isSelected: rideType == "offer"
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) { rideType = "offer" }
                }
                rideTypeCard(
                    title: "Need a Ride",
                    subtitle: "You're riding",
                    icon: "hand.raised.fill",
                    accent: Theme.Colors.primary,
                    isSelected: rideType == "request"
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) { rideType = "request" }
                }
            }
        }
    }

    private func rideTypeCard(title: String, subtitle: String, icon: String, accent: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected
                              ? AnyShapeStyle(LinearGradient(colors: [accent, accent.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
                              : AnyShapeStyle(Theme.Colors.inputBackground))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : Theme.Colors.textSecondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.inter(.bold, size: 14))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(subtitle)
                        .font(.inter(.regular, size: 12))
                        .foregroundStyle(Theme.Colors.textLight)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.Colors.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? accent : Theme.Colors.border, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Route

    private var routeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route")
                .font(.inter(.bold, size: 16))
                .foregroundStyle(Theme.Colors.textPrimary)

            ZStack(alignment: .trailing) {
                VStack(spacing: 10) {
                    LocationAutocompleteField(icon: "circle.fill", placeholder: "Leaving from", text: $from, coordinate: $fromCoordinate)
                    LocationAutocompleteField(icon: "mappin.circle.fill", placeholder: "Going to", text: $to, coordinate: $toCoordinate)
                }

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        swap(&from, &to)
                        swap(&fromCoordinate, &toCoordinate)
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            LinearGradient(colors: Theme.Colors.primaryGradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: Circle()
                        )
                        .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .padding(.trailing, 14)
            }
        }
    }

    // MARK: Date + Seats

    private var dateAndSeatsSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("When")
                    .font(.inter(.bold, size: 16))
                    .foregroundStyle(Theme.Colors.textPrimary)

                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(typeAccent)
                    DatePicker("", selection: $rideDate)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(typeAccent)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(isOffering ? "Seats available" : "Seats needed")
                    .font(.inter(.bold, size: 16))
                    .foregroundStyle(Theme.Colors.textPrimary)

                HStack {
                    Text("\(seats)")
                        .font(.inter(.heavy, size: 20))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(minWidth: 30)

                    Text(seats == 1 ? "seat" : "seats")
                        .font(.inter(.medium, size: 14))
                        .foregroundStyle(Theme.Colors.textLight)

                    Spacer()

                    HStack(spacing: 14) {
                        stepperButton(icon: "minus", disabled: seats <= 1) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { seats = max(1, seats - 1) }
                        }
                        stepperButton(icon: "plus", disabled: seats >= 8) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { seats = min(8, seats + 1) }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
            }
        }
    }

    private func stepperButton(icon: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(disabled ? Theme.Colors.textLight : .white)
                .frame(width: 30, height: 30)
                .background(
                    disabled
                        ? AnyShapeStyle(Theme.Colors.inputBackground)
                        : AnyShapeStyle(LinearGradient(colors: Theme.Colors.primaryGradient, startPoint: .top, endPoint: .bottom)),
                    in: Circle()
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    // MARK: Category

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.inter(.bold, size: 16))
                .foregroundStyle(Theme.Colors.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(RideCategoryKind.allCases.filter { $0 != .all }) { kind in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { category = kind }
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(category == kind
                                          ? AnyShapeStyle(LinearGradient(colors: [categoryAccent(kind), categoryAccent(kind).opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                          : AnyShapeStyle(Theme.Colors.inputBackground))
                                    .frame(width: 34, height: 34)
                                Image(systemName: kind.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(category == kind ? .white : Theme.Colors.textSecondary)
                            }
                            Text(kind.displayName)
                                .font(.inter(.semibold, size: 13))
                                .foregroundStyle(category == kind ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Theme.Colors.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(category == kind ? categoryAccent(kind) : Theme.Colors.border, lineWidth: category == kind ? 2 : 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func categoryAccent(_ kind: RideCategoryKind) -> Color {
        switch kind {
        case .all:        Theme.Colors.primary
        case .airport:    Theme.Colors.info
        case .university: Theme.Colors.secondary
        case .religious:  Theme.Colors.success
        case .general:    Theme.Colors.carpoolAccent
        case .longRide:   Theme.Colors.warning
        }
    }

    // MARK: Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notes (optional)")
                .font(.inter(.bold, size: 16))
                .foregroundStyle(Theme.Colors.textPrimary)

            TextField("Anything riders should know? Luggage space, pickup spot…", text: $notes, axis: .vertical)
                .font(.inter(.regular, size: 15))
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(14)
                .frame(minHeight: 90, alignment: .top)
                .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
        }
    }

    // MARK: Post Button

    private var postButton: some View {
        Button {
            Task { await post() }
        } label: {
            Group {
                if isPosting {
                    ProgressView().tint(.white)
                } else {
                    Text(isOffering ? "Post Ride Offer" : "Post Ride Request")
                        .font(.inter(.bold, size: 16))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(colors: Theme.Colors.primaryGradient, startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .shadow(color: Theme.Colors.primary.opacity(0.28), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!canPost || isPosting)
        .opacity(canPost ? 1 : 0.5)
    }

    // MARK: Submit

    private func post() async {
        guard let userId = auth.currentUser?.id else { return }
        isPosting = true
        defer { isPosting = false }
        do {
            _ = try await ridesService.post(
                userId: userId,
                rideType: rideType,
                fromLocation: from,
                toLocation: to,
                fromCoordinate: fromCoordinate,
                toCoordinate: toCoordinate,
                rideDate: rideDate,
                seatsAvailable: seats,
                price: nil,
                notes: notes,
                category: category.rawValue
            )
            withAnimation(.easeIn(duration: 0.18)) { showSuccess = true }
        } catch {
            // Leave the form as-is so the user can retry.
            postFailed = true
        }
    }
}

// MARK: - Ride Post Success Overlay

private struct RidePostSuccessOverlay: View {
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
                    Text("Ride Posted!")
                        .font(.inter(.heavy, size: 22))
                        .foregroundStyle(.white)
                    Text("Riders nearby will be able\nto see it right away.")
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

struct EditRideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RidesService.self) private var ridesService
    let ride: Ride
    @State private var from: String
    @State private var to: String
    @State private var notes: String
    @State private var fromCoordinate: CLLocationCoordinate2D?
    @State private var toCoordinate: CLLocationCoordinate2D?
    @State private var isSaving = false

    init(ride: Ride) {
        self.ride = ride
        _from = State(initialValue: ride.fromLocation)
        _to = State(initialValue: ride.toLocation)
        _notes = State(initialValue: ride.notes ?? "")
        _fromCoordinate = State(initialValue: ride.fromCoordinate)
        _toCoordinate = State(initialValue: ride.toCoordinate)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("From", text: $from)
                    // Editing the text by hand invalidates the pin picked when the
                    // ride was first posted — it no longer necessarily matches.
                    .onChange(of: from) { _, _ in fromCoordinate = nil }
                TextField("To", text: $to)
                    .onChange(of: to) { _, _ in toCoordinate = nil }
                if fromCoordinate == nil || toCoordinate == nil {
                    Text("Route map will be unavailable until this ride is re-posted with a picked location.")
                        .font(.inter(.regular, size: 12))
                        .foregroundStyle(.secondary)
                }
                TextField("Notes", text: $notes, axis: .vertical)
            }
            .navigationTitle("Edit Ride")
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
        var updates: [String: AnyJSON] = [
            "from_location": .string(from),
            "to_location":   .string(to),
            "notes":         .string(notes),
        ]
        updates["from_lat"] = fromCoordinate.map { .double($0.latitude) } ?? .null
        updates["from_lng"] = fromCoordinate.map { .double($0.longitude) } ?? .null
        updates["to_lat"]   = toCoordinate.map { .double($0.latitude) } ?? .null
        updates["to_lng"]   = toCoordinate.map { .double($0.longitude) } ?? .null
        try? await ridesService.update(id: ride.id, updates: updates)
        isSaving = false
        dismiss()
    }
}
