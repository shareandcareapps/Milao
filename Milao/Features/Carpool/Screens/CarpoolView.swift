import SwiftUI

struct CarpoolView: View {
    @State private var selectedCategory: RideCategory = .all
    @State private var showingPostRide = false

    private var filteredRides: [RidePost] {
        CommunitySamples.rides.filter { ride in
            selectedCategory == .all || ride.category == selectedCategory
        }
    }

    private var offeringCount: Int { filteredRides.filter { $0.type == .offer }.count }
    private var requestingCount: Int { filteredRides.filter { $0.type == .request }.count }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Theme.Colors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        carpoolHeader

                        HStack(spacing: 16) {
                            StatPill(title: "\(offeringCount) offering", icon: "car.fill", color: Theme.Colors.info)
                            StatPill(title: "\(requestingCount) requesting", icon: "hand.raised.fill", color: Theme.Colors.warning)
                            Spacer()
                        }
                        .padding(.horizontal, Theme.Spacing.lg)

                        LazyVStack(spacing: 18) {
                            ForEach(filteredRides) { ride in
                                NavigationLink(destination: RideDetailView(ride: ride)) {
                                    RideRouteCard(ride: ride)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 120)
                    }
                }

                Button {
                    showingPostRide = true
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
            .sheet(isPresented: $showingPostRide) {
                PostRideView()
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
        VStack(alignment: .leading, spacing: 28) {
            HStack {
                Text("Carpool")
                    .font(Theme.Fonts.nunitoExtraBold(size: 31))
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
        .padding(.bottom, 22)
        .background(
            LinearGradient(colors: Theme.Colors.headerGradientLight, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)
        )
    }
}

private struct StatPill: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(title)
        }
        .font(Theme.Fonts.nunitoBold(size: 14))
        .foregroundStyle(color)
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(color.opacity(0.11), in: Capsule())
    }
}

private struct RideRouteCard: View {
    let ride: RidePost

    private var accent: Color { ride.type.color }
    private var badgeTitle: String { ride.type == .offer ? "Offering" : "Need Seat" }
    private var badgeIcon: String { ride.type == .offer ? "car.fill" : "hand.raised.fill" }
    private var seatText: String { ride.type == .offer ? "\(ride.seats) seats" : "\(ride.seats) needed" }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Text(String(ride.driver.prefix(1)))
                    .font(Theme.Fonts.nunitoExtraBold(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        LinearGradient(colors: [Theme.Colors.primary, Theme.Colors.secondary], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: Circle()
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        Text(ride.driver)
                            .font(Theme.Fonts.nunitoExtraBold(size: 18))
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Image(systemName: "map")
                            .font(.system(size: 21, weight: .regular))
                            .foregroundStyle(Theme.Colors.textLight)
                    }
                }

                Spacer()

                HStack(spacing: 7) {
                    Image(systemName: badgeIcon)
                    Text(badgeTitle)
                }
                .font(Theme.Fonts.nunitoBold(size: 13))
                .foregroundStyle(accent)
                .padding(.horizontal, 13)
                .frame(height: 40)
                .background(accent.opacity(0.1), in: Capsule())
                .overlay(Capsule().stroke(accent.opacity(0.24), lineWidth: 1))
            }

            HStack(alignment: .top, spacing: 18) {
                VStack(spacing: 6) {
                    Circle().fill(accent).frame(width: 14, height: 14)
                    Rectangle().fill(accent.opacity(0.22)).frame(width: 4, height: 32)
                    Circle().stroke(accent, lineWidth: 4).frame(width: 14, height: 14)
                }
                .padding(.top, 7)

                VStack(alignment: .leading, spacing: 22) {
                    Text(ride.from)
                    Text(ride.to)
                }
                .font(Theme.Fonts.nunitoExtraBold(size: 21))
                .foregroundStyle(Theme.Colors.textPrimary)
            }
            .padding(.leading, 4)

            HStack(spacing: 10) {
                RideMetaPill(text: ride.date, icon: "calendar", color: accent)
                RideMetaPill(text: ride.time, icon: "clock", color: accent)
                RideMetaPill(text: seatText, icon: "person.2", color: accent)
            }
        }
        .padding(18)
        .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(alignment: .top) {
            Capsule()
                .fill(accent)
                .frame(height: 5)
                .padding(.horizontal, 24)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(accent.opacity(0.18), lineWidth: 1.4)
        )
        .shadow(color: .black.opacity(0.04), radius: 16, x: 0, y: 8)
    }
}

private struct RideMetaPill: View {
    let text: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(Theme.Fonts.nunitoBold(size: 14))
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(color.opacity(0.1), in: Capsule())
    }
}

struct RideDetailView: View {
    let ride: RidePost
    @State private var showingChat = false
    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RideRouteCard(ride: ride)
                    .padding(.top, 16)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Trip Details")
                        .font(Theme.Fonts.nunitoExtraBold(size: 24))
                    Text(ride.notes)
                        .font(Theme.Fonts.interRegular(size: 17))
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Label(ride.category.rawValue, systemImage: ride.category.icon)
                        .font(Theme.Fonts.interMedium(size: 16))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(spacing: 12) {
                    PrimaryButton(ride.type == .offer ? "Request Seat" : "Offer Ride") { showingChat = true }
                    Button("Edit Ride") { showingEdit = true }
                        .buttonStyle(.bordered)
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Ride")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingChat) {
            ChatView(conversation: CommunityConversation(name: ride.driver, subject: "\(ride.from) to \(ride.to)", preview: "Hi, is this ride available?", timestamp: "now", tint: ride.type.color))
        }
        .sheet(isPresented: $showingEdit) {
            EditRideView(ride: ride)
        }
    }
}

struct PostRideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var from = ""
    @State private var to = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("From", text: $from)
                TextField("To", text: $to)
                TextField("Notes", text: $notes, axis: .vertical)
            }
            .navigationTitle("New Ride")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Post") { dismiss() } }
            }
        }
    }
}

struct EditRideView: View {
    @Environment(\.dismiss) private var dismiss
    let ride: RidePost
    @State private var from: String
    @State private var to: String
    @State private var notes: String

    init(ride: RidePost) {
        self.ride = ride
        _from = State(initialValue: ride.from)
        _to = State(initialValue: ride.to)
        _notes = State(initialValue: ride.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("From", text: $from)
                TextField("To", text: $to)
                TextField("Notes", text: $notes, axis: .vertical)
            }
            .navigationTitle("Edit Ride")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { dismiss() } }
            }
        }
    }
}
