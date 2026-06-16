import SwiftUI

struct SettingsView: View {
    @Environment(AuthService.self) private var auth

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                profileCard

                SettingsGroup(title: "Account") {
                    SettingsLinkRow(title: "Edit Profile", subtitle: "Name, username, bio, and city", icon: "person.fill", destination: EditProfileView())
                    SettingsLinkRow(title: "My Listings", subtitle: "Manage market posts", icon: "rectangle.stack.fill", destination: MyListingsView())
                    SettingsLinkRow(title: "My Rides", subtitle: "Manage ride offers and requests", icon: "car.2.fill", destination: MyRidesView())
                }

                SettingsGroup(title: "Community") {
                    SettingsLinkRow(title: "Feedback", subtitle: "Send suggestions or report problems", icon: "bubble.left.and.text.bubble.right.fill", destination: FeedbackView())
                    SettingsLinkRow(title: "Admin Panel", subtitle: "Moderation and community health", icon: "shield.lefthalf.filled", destination: AdminPanelView())
                    SettingsLinkRow(title: "Onboarding", subtitle: "Review the welcome walkthrough", icon: "sparkles", destination: OnboardingView())
                }

                SettingsGroup(title: "Legal") {
                    SettingsLinkRow(title: "Privacy Policy", subtitle: "How community data is handled", icon: "hand.raised.fill", destination: LegalTextView(kind: .privacy))
                    SettingsLinkRow(title: "Terms & Conditions", subtitle: "Rules for using Milao", icon: "doc.text.fill", destination: LegalTextView(kind: .terms))
                    SettingsLinkRow(title: "Disclaimer", subtitle: "Marketplace and rides limitations", icon: "exclamationmark.triangle.fill", destination: LegalTextView(kind: .disclaimer))
                }

                Button(role: .destructive) {
                    Task { await auth.signOut() }
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.inter(.bold, size: 15))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .buttonStyle(.glass)
            }
            .padding(Theme.Spacing.lg)
        }
        .appBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    private var profileCard: some View {
        HStack(spacing: 14) {
            InitialsAvatar(name: auth.currentUser?.fullName ?? "Community Member", color: Theme.Colors.primary, size: 62)
            VStack(alignment: .leading, spacing: 5) {
                Text(auth.currentUser?.fullName ?? "Community Member")
                    .font(.nunito(.bold, size: 21))
                Text(auth.currentUser?.username.map { "@\($0)" } ?? "Complete your Milao profile")
                    .font(.inter(.regular, size: 13))
                    .foregroundStyle(.secondary)
                Label("\(auth.currentUser?.points ?? 0) community points", systemImage: "bolt.fill")
                    .font(.inter(.bold, size: 12))
                    .foregroundStyle(Theme.Colors.primary)
            }
            Spacer()
        }
        .padding(18)
        .modernGlassPanel()
    }
}

private struct SettingsGroup<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.inter(.bold, size: 13))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            VStack(spacing: 0) {
                content
            }
            .modernGlassPanel()
        }
    }
}

private struct SettingsLinkRow<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let destination: Destination

    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 13) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.primary)
                    .frame(width: 34, height: 34)
                    .background(Theme.Colors.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.inter(.semibold, size: 15))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.inter(.regular, size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }
}

struct EditProfileView: View {
    @Environment(AuthService.self) private var auth
    @State private var fullName = ""
    @State private var username = ""
    @State private var city = "St. Louis"
    @State private var bio = ""

    var body: some View {
        Form {
            Section("Profile") {
                TextField("Full name", text: $fullName)
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                TextField("City", text: $city)
                TextEditor(text: $bio)
                    .frame(minHeight: 100)
            }
        }
        .navigationTitle("Edit Profile")
        .onAppear {
            fullName = auth.currentUser?.fullName ?? ""
            username = auth.currentUser?.username ?? ""
            city = auth.currentUser?.city ?? "St. Louis"
            bio = auth.currentUser?.bio ?? ""
        }
    }
}

struct FeedbackView: View {
    @State private var topic = "Suggestion"
    @State private var message = ""
    private let topics = ["Suggestion", "Bug", "Safety", "Marketplace", "Rides"]

    var body: some View {
        Form {
            Picker("Topic", selection: $topic) {
                ForEach(topics, id: \.self) { Text($0).tag($0) }
            }
            Section("Message") {
                TextEditor(text: $message)
                    .frame(minHeight: 180)
            }
            Section {
                Button("Submit Feedback") {
                    message = ""
                }
                .disabled(message.isEmpty)
            }
        }
        .navigationTitle("Feedback")
    }
}

struct AdminPanelView: View {
    private let metrics = [
        ("Open reports", "7", "exclamationmark.triangle.fill", Theme.Colors.accent),
        ("Pending listings", "14", "rectangle.stack.badge.plus", Theme.Colors.marketAccent),
        ("Ride flags", "3", "car.fill", Theme.Colors.carpoolAccent),
        ("New users", "128", "person.3.fill", Theme.Colors.messagesAccent)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                GlassHeader(title: "Admin", subtitle: "Moderation queue and community health", icon: "shield.lefthalf.filled", colors: [Theme.Colors.secondary, Theme.Colors.messagesAccent])

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    ForEach(metrics, id: \.0) { metric in
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: metric.2)
                                .foregroundStyle(metric.3)
                            Text(metric.1)
                                .font(.nunito(.black, size: 30))
                            Text(metric.0)
                                .font(.inter(.semibold, size: 13))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .modernGlassPanel()
                    }
                }

                GlassSectionHeader("Actions")
                VStack(spacing: 12) {
                    AdminActionRow(title: "Review flagged listing", subtitle: "MacBook Air M2 · Clayton")
                    AdminActionRow(title: "Ride report needs response", subtitle: "Airport pickup · Today")
                    AdminActionRow(title: "Approve event post", subtitle: "Summer Garba Night")
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .appBackground()
        .navigationTitle("Admin Panel")
    }
}

private struct AdminActionRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.inter(.bold, size: 15))
                Text(subtitle).font(.inter(.regular, size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Review") {}
                .buttonStyle(.glass)
        }
        .padding(14)
        .modernGlassPanel()
    }
}

struct MyListingsView: View {
    var body: some View {
        List(CommunitySamples.listings.prefix(3)) { listing in
            NavigationLink {
                ListingDetailView(listing: listing)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.title).font(.inter(.bold, size: 15))
                    Text("\(listing.price) · \(listing.status.rawValue)").font(.inter(.regular, size: 12)).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("My Listings")
    }
}

struct MyRidesView: View {
    var body: some View {
        List(CommunitySamples.rides.prefix(3)) { ride in
            NavigationLink {
                RideDetailView(ride: ride)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(ride.from) to \(ride.to)").font(.inter(.bold, size: 15))
                    Text("\(ride.type.rawValue) · \(ride.date), \(ride.time)").font(.inter(.regular, size: 12)).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("My Rides")
    }
}

struct OnboardingView: View {
    private let pages = [
        ("Find your community", "Connect with South Asian neighbors across St. Louis.", "person.3.fill", Theme.Colors.primary),
        ("Share rides safely", "Coordinate cost-sharing rides for airport, campus, temple, and long trips.", "car.fill", Theme.Colors.carpoolAccent),
        ("Buy, sell, and help", "Post housing, jobs, food, services, and events with community trust.", "storefront.fill", Theme.Colors.marketAccent)
    ]

    var body: some View {
        TabView {
            ForEach(pages, id: \.0) { page in
                VStack(spacing: 22) {
                    Image(systemName: page.2)
                        .font(.system(size: 46, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 112, height: 112)
                        .background(page.3.gradient, in: RoundedRectangle(cornerRadius: 30))
                    Text(page.0)
                        .font(.nunito(.black, size: 28))
                    Text(page.1)
                        .font(.inter(.regular, size: 16))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .tabViewStyle(.page)
        .appBackground()
        .navigationTitle("Welcome")
    }
}

struct LegalTextView: View {
    enum Kind {
        case privacy, terms, disclaimer

        var title: String {
            switch self {
            case .privacy: "Privacy Policy"
            case .terms: "Terms & Conditions"
            case .disclaimer: "Disclaimer"
            }
        }

        var bodyText: String {
            switch self {
            case .privacy:
                "Milao uses account, profile, listing, ride, and message data to provide community features, safety moderation, and support. Do not share sensitive personal information in public posts."
            case .terms:
                "Use Milao respectfully. Listings must be lawful and accurate. Ride posts are peer-to-peer cost-sharing arrangements, and users are responsible for confirming details before meeting."
            case .disclaimer:
                "Milao is a community platform. It is not a transportation network company, broker, employer, housing provider, food vendor, or payment intermediary. Users transact and coordinate at their own discretion."
            }
        }
    }

    let kind: Kind

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(kind.title)
                    .font(.nunito(.black, size: 30))
                Text(kind.bodyText)
                    .font(.inter(.regular, size: 16))
                    .foregroundStyle(.secondary)
                    .lineSpacing(6)
                Text("Last updated: June 16, 2026")
                    .font(.inter(.regular, size: 12))
                    .foregroundStyle(.tertiary)
            }
            .padding(Theme.Spacing.lg)
        }
        .appBackground()
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
