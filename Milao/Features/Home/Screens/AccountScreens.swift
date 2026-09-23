import SwiftUI
import Supabase
import PhotosUI

struct SettingsView: View {
    @Environment(AuthService.self) private var auth
    @Environment(ThemeManager.self) private var themeManager
    @State private var showDeleteAccount = false

    private var isDark: Bool { themeManager.theme != .light }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                profileCard

                SettingsGroup(title: "Account") {
                    SettingsLinkRow(title: "Edit Profile", subtitle: "Name, username, bio, and city", icon: "person.fill", destination: EditProfileView())
                    SettingsLinkRow(title: "My Listings", subtitle: "Manage market posts", icon: "rectangle.stack.fill", destination: MyListingsView())
                    SettingsLinkRow(title: "My Rides", subtitle: "Manage ride offers and requests", icon: "car.2.fill", destination: MyRidesView())
                    if auth.biometricLoginEnabled {
                        biometricToggleRow
                    }
                }

                SettingsGroup(title: "Privacy & Safety") {
                    SettingsLinkRow(title: "Blocked Users", subtitle: "People you won't hear from", icon: "person.crop.circle.badge.xmark", destination: BlockedUsersView())
                }

                SettingsGroup(title: "Community") {
                    SettingsLinkRow(title: "Feedback", subtitle: "Send suggestions or report problems", icon: "bubble.left.and.text.bubble.right.fill", destination: FeedbackView())
                    if auth.currentUser?.isAdmin == true {
                        SettingsLinkRow(title: "Admin Panel", subtitle: "Moderation and community health", icon: "shield.lefthalf.filled", destination: AdminPanelView())
                    }
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
                    Label(auth.currentUser == nil ? "Sign In" : "Sign Out",
                          systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.inter(.bold, size: 15))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .buttonStyle(.glass)

                if auth.currentUser != nil {
                    Button {
                        showDeleteAccount = true
                    } label: {
                        Text("Delete Account")
                            .font(.inter(.semibold, size: 13))
                            .foregroundStyle(Theme.Colors.error)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .appBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                themeToggle
            }
        }
        .sheet(isPresented: $showDeleteAccount) {
            DeleteAccountView()
        }
    }

    private var biometricToggleRow: some View {
        Button {
            auth.disableBiometricLogin()
        } label: {
            HStack(spacing: 13) {
                Image(systemName: auth.biometricSystemImage())
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.primary)
                    .frame(width: 34, height: 34)
                    .background(Theme.Colors.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(auth.biometricLabel()) Login")
                        .font(.inter(.semibold, size: 15))
                        .foregroundStyle(.primary)
                    Text("Enabled — tap to turn off")
                        .font(.inter(.regular, size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.Colors.success)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }

    private var themeToggle: some View {
        ZStack {
            Image(isDark ? "ToggleDark" : "ToggleLight")
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 36)
                .rotationEffect(.degrees(90))
                .clipShape(Capsule())
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDark)

            HStack(spacing: 0) {
                ZStack {
                    Circle().fill(.white).frame(width: 30, height: 30).opacity(!isDark ? 1 : 0)
                    Image("LightSwitch").resizable().scaledToFit().frame(width: 20, height: 20).opacity(!isDark ? 1 : 0.4)
                }
                .frame(width: 36)

                ZStack {
                    Circle().fill(.white).frame(width: 30, height: 30).opacity(isDark ? 1 : 0)
                    Image("NightSwitch").resizable().scaledToFit().frame(width: 18, height: 18).opacity(isDark ? 1 : 0.4)
                }
                .frame(width: 36)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDark)
        }
        .frame(width: 72, height: 36)
        .onTapGesture {
            themeManager.setTheme(isDark ? .light : .dark)
        }
    }

    private var profileCard: some View {
        HStack(spacing: 14) {
            InitialsAvatar(name: auth.currentUser?.fullName ?? "Community Member", color: Theme.Colors.primary, size: 62, imageURL: auth.currentUser?.avatarURL)
            VStack(alignment: .leading, spacing: 5) {
                Text(auth.currentUser?.fullName ?? "Community Member")
                    .font(.nunito(.bold, size: 21))
                Text(auth.currentUser?.username.map { "@\($0)" } ?? "Complete your Milao profile")
                    .font(.inter(.regular, size: 14))
                    .foregroundStyle(.secondary)
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
                .font(.inter(.bold, size: 14))
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
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var username = ""
    @State private var city = "St. Louis"
    @State private var bio = ""
    @State private var isSaving = false
    @State private var saveFailed = false
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    @State private var photoUploadFailed = false

    private var canSave: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    avatarPicker
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)

            Section("Profile") {
                TextField("Full name", text: $fullName)
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("City", text: $city)
                TextEditor(text: $bio)
                    .frame(minHeight: 100)
            }
        }
        .navigationTitle("Edit Profile")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isSaving {
                    ProgressView()
                } else {
                    Button("Save") { Task { await save() } }
                        .disabled(!canSave)
                }
            }
        }
        .alert("Couldn't save profile", isPresented: $saveFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(auth.errorMessage ?? "Please check your connection and try again.")
        }
        .alert("Couldn't update photo", isPresented: $photoUploadFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(auth.errorMessage ?? "Please check your connection and try again.")
        }
        .onChange(of: pickedPhoto) { _, newItem in
            guard let newItem else { return }
            Task { await uploadPhoto(newItem) }
        }
        .onAppear {
            fullName = auth.currentUser?.fullName ?? ""
            username = auth.currentUser?.username ?? ""
            city = auth.currentUser?.city ?? "St. Louis"
            bio = auth.currentUser?.bio ?? ""
        }
    }

    private var avatarPicker: some View {
        PhotosPicker(selection: $pickedPhoto, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                InitialsAvatar(
                    name: auth.currentUser?.fullName ?? "Member",
                    color: Theme.Colors.primary,
                    size: 96,
                    imageURL: auth.currentUser?.avatarURL
                )
                .opacity(isUploadingPhoto ? 0.4 : 1)

                if isUploadingPhoto {
                    ProgressView()
                        .frame(width: 96, height: 96)
                } else {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Theme.Colors.primary, in: Circle())
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isUploadingPhoto)
    }

    private func uploadPhoto(_ item: PhotosPickerItem) async {
        isUploadingPhoto = true
        defer { isUploadingPhoto = false; pickedPhoto = nil }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        if !(await auth.updateAvatar(data)) {
            photoUploadFailed = true
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        if await auth.updateProfile(fullName: fullName, username: username, city: city, bio: bio) {
            dismiss()
        } else {
            saveFailed = true
        }
    }
}

struct FeedbackView: View {
    @Environment(AuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var topic = "Suggestion"
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var didSubmit = false
    @State private var didFail = false
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
                Button {
                    Task { await submit() }
                } label: {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text("Submit Feedback")
                    }
                }
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            }
        }
        .navigationTitle("Feedback")
        .alert("Thank you!", isPresented: $didSubmit) {
            Button("Done") { dismiss() }
        } message: {
            Text("Your feedback helps make Milao better for everyone.")
        }
        .alert("Couldn't send feedback", isPresented: $didFail) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please check your connection and try again.")
        }
    }

    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }
        var payload: [String: AnyJSON] = [
            "topic":   .string(topic),
            "message": .string(message.trimmingCharacters(in: .whitespacesAndNewlines)),
        ]
        if let userId = auth.currentUser?.id {
            payload["user_id"] = .string(userId.uuidString)
        }
        do {
            try await supabase.from("feedback").insert(payload).execute()
            message = ""
            didSubmit = true
        } catch {
            didFail = true
        }
    }
}

struct AdminPanelView: View {
    @Environment(AdminService.self) private var adminService
    @State private var reviewingReport: AdminReport?

    private var metrics: [(String, String, String, Color)] {
        let reports = adminService.reports
        return [
            ("Open reports",   "\(reports.count)", "exclamationmark.triangle.fill", Theme.Colors.accent),
            ("Listing reports", "\(reports.filter { $0.listingId != nil }.count)", "rectangle.stack.badge.plus", Theme.Colors.marketAccent),
            ("Ride reports",   "\(reports.filter { $0.rideId != nil }.count)", "car.fill", Theme.Colors.carpoolAccent),
            ("New users (7d)", "\(adminService.newUsersLast7Days)", "person.3.fill", Theme.Colors.messagesAccent),
        ]
    }

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

                GlassSectionHeader("Open Reports")
                if adminService.isLoading && adminService.reports.isEmpty {
                    ProgressView().frame(maxWidth: .infinity)
                } else if adminService.error != nil && adminService.reports.isEmpty {
                    LoadFailedView { Task { await adminService.fetchDashboard() } }
                } else if adminService.reports.isEmpty {
                    EmptyStateView(icon: "checkmark.shield", title: "All clear", message: "No open reports right now.")
                } else {
                    VStack(spacing: 12) {
                        ForEach(adminService.reports) { report in
                            AdminReportRow(report: report) {
                                reviewingReport = report
                            }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .appBackground()
        .navigationTitle("Admin Panel")
        .task { await adminService.fetchDashboard() }
        .refreshable { await adminService.fetchDashboard() }
        .sheet(item: $reviewingReport) { report in
            ReportReviewSheet(report: report)
        }
    }
}

private struct AdminReportRow: View {
    let report: AdminReport
    let onReview: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(report.reason).font(.inter(.bold, size: 15))
                Text(report.targetSummary).font(.inter(.regular, size: 12)).foregroundStyle(.secondary)
                if let reporterName = report.reporter?.fullName {
                    Text("Reported by \(reporterName) · \(report.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.inter(.regular, size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Button("Review", action: onReview)
                .buttonStyle(.glass)
        }
        .padding(14)
        .modernGlassPanel()
    }
}

// MARK: - Report Review

private struct ReportReviewSheet: View {
    let report: AdminReport
    @Environment(AdminService.self) private var adminService
    @Environment(ListingsService.self) private var listingsService
    @Environment(RidesService.self) private var ridesService
    @Environment(\.dismiss) private var dismiss
    @State private var isWorking = false
    @State private var didFail = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Report") {
                    LabeledContent("Reason", value: report.reason)
                    if let notes = report.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Details").font(.inter(.semibold, size: 13)).foregroundStyle(.secondary)
                            Text(notes).font(.inter(.regular, size: 14))
                        }
                    }
                    if let reporterName = report.reporter?.fullName {
                        LabeledContent("Reported by", value: reporterName)
                    }
                    LabeledContent("Filed", value: report.createdAt.formatted(date: .abbreviated, time: .shortened))
                }

                Section("What's being reported") {
                    Text(report.targetSummary)
                        .font(.inter(.regular, size: 14))
                        .foregroundStyle(.secondary)
                }

                if report.reportedUserId != nil || report.listingId != nil || report.rideId != nil {
                    Section("Moderation actions") {
                        if let reportedUser = report.reportedUserId {
                            Button(role: .destructive) {
                                Task { await suspendUser(reportedUser) }
                            } label: {
                                Label("Suspend \(report.reportedUser?.fullName ?? "user")", systemImage: "person.fill.xmark")
                            }
                        }
                        if let listingId = report.listingId {
                            Button(role: .destructive) {
                                Task { await removeListing(listingId) }
                            } label: {
                                Label("Remove listing", systemImage: "trash")
                            }
                        }
                        if let rideId = report.rideId {
                            Button(role: .destructive) {
                                Task { await cancelRide(rideId) }
                            } label: {
                                Label("Cancel ride", systemImage: "car.fill")
                            }
                        }
                    }
                }

                Section {
                    Button("Dismiss Report") {
                        Task { await updateStatus("dismissed") }
                    }
                    Button("Mark Resolved") {
                        Task { await updateStatus("resolved") }
                    }
                    .fontWeight(.semibold)
                }
            }
            .disabled(isWorking)
            .navigationTitle("Review Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                if isWorking {
                    ToolbarItem(placement: .confirmationAction) { ProgressView() }
                }
            }
            .alert("Something went wrong", isPresented: $didFail) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please check your connection and try again.")
            }
        }
    }

    private func updateStatus(_ status: String) async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await adminService.updateReportStatus(id: report.id, status: status)
            dismiss()
        } catch {
            didFail = true
        }
    }

    private func suspendUser(_ userId: UUID) async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await adminService.suspendUser(id: userId)
            try await adminService.updateReportStatus(id: report.id, status: "resolved")
            dismiss()
        } catch {
            didFail = true
        }
    }

    private func removeListing(_ listingId: UUID) async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await listingsService.delete(id: listingId)
            try await adminService.updateReportStatus(id: report.id, status: "resolved")
            dismiss()
        } catch {
            didFail = true
        }
    }

    private func cancelRide(_ rideId: UUID) async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await ridesService.delete(id: rideId)
            try await adminService.updateReportStatus(id: report.id, status: "resolved")
            dismiss()
        } catch {
            didFail = true
        }
    }
}

struct MyListingsView: View {
    @Environment(AuthService.self) private var auth
    @Environment(ListingsService.self) private var listingsService
    @State private var myListings: [Listing] = []
    @State private var isLoading = false

    var body: some View {
        Group {
            if isLoading && myListings.isEmpty {
                ProgressView()
            } else if listingsService.error != nil && myListings.isEmpty {
                LoadFailedView { Task { await load() } }
            } else if myListings.isEmpty {
                EmptyStateView(icon: "bag", title: "No listings yet", message: "Posts you create will show up here.")
            } else {
                List {
                    ForEach(myListings) { listing in
                        NavigationLink {
                            ListingDetailView(listing: listing)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(listing.title).font(.inter(.bold, size: 15))
                                Text("\(listing.formattedPrice ?? "—") · \(listing.status.capitalized)").font(.inter(.regular, size: 12)).foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    try? await listingsService.delete(id: listing.id)
                                    myListings.removeAll { $0.id == listing.id }
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            if listing.status == "active" {
                                Button {
                                    Task {
                                        try? await listingsService.markSold(id: listing.id)
                                        if let idx = myListings.firstIndex(where: { $0.id == listing.id }) {
                                            myListings[idx].status = "sold"
                                        }
                                    }
                                } label: {
                                    Label("Sold", systemImage: "checkmark.circle")
                                }
                                .tint(Theme.Colors.success)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("My Listings")
        .task { await load() }
    }

    private func load() async {
        guard let userId = auth.currentUser?.id else { return }
        isLoading = true
        myListings = await listingsService.fetchMine(userId: userId)
        isLoading = false
    }
}

struct MyRidesView: View {
    @Environment(AuthService.self) private var auth
    @Environment(RidesService.self) private var ridesService
    @State private var isLoading = false

    var body: some View {
        Group {
            if isLoading && ridesService.myRides.isEmpty {
                ProgressView()
            } else if ridesService.error != nil && ridesService.myRides.isEmpty {
                LoadFailedView { Task { await load() } }
            } else if ridesService.myRides.isEmpty {
                EmptyStateView(icon: "car", title: "No rides yet", message: "Rides you offer or request will show up here.")
            } else {
                List {
                    ForEach(ridesService.myRides) { ride in
                        NavigationLink {
                            RideDetailView(ride: ride)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(ride.fromLocation) to \(ride.toLocation)").font(.inter(.bold, size: 15))
                                Text("\(ride.isOffering ? "Offering" : "Requesting") · \(ride.formattedDate)").font(.inter(.regular, size: 12)).foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { try? await ridesService.delete(id: ride.id) }
                            } label: {
                                Label("Cancel Ride", systemImage: "xmark.circle")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("My Rides")
        .task { await load() }
    }

    private func load() async {
        guard let userId = auth.currentUser?.id else { return }
        isLoading = true
        await ridesService.fetchMine(userId: userId)
        isLoading = false
    }
}

struct BlockedUsersView: View {
    @Environment(AuthService.self) private var auth
    @Environment(BlockedUsersService.self) private var blockedUsersService

    var body: some View {
        Group {
            if blockedUsersService.isLoading && blockedUsersService.blockedUsers.isEmpty {
                ProgressView()
            } else if blockedUsersService.error != nil && blockedUsersService.blockedUsers.isEmpty {
                LoadFailedView { Task { await blockedUsersService.fetchBlockedUsers() } }
            } else if blockedUsersService.blockedUsers.isEmpty {
                EmptyStateView(icon: "person.crop.circle.badge.checkmark", title: "No one blocked", message: "People you block won't be able to message you.")
            } else {
                List {
                    ForEach(blockedUsersService.blockedUsers) { entry in
                        HStack {
                            Text(entry.blocked?.fullName ?? "Milao member")
                                .font(.inter(.semibold, size: 15))
                            Spacer()
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                guard let myId = auth.currentUser?.id else { return }
                                Task { try? await blockedUsersService.unblock(blockerId: myId, blockedId: entry.blockedId) }
                            } label: {
                                Label("Unblock", systemImage: "person.crop.circle.badge.checkmark")
                            }
                            .tint(Theme.Colors.success)
                        }
                    }
                }
            }
        }
        .navigationTitle("Blocked Users")
        .task { await blockedUsersService.fetchBlockedUsers() }
    }
}

struct OnboardingView: View {
    /// Set only for the first-launch presentation (see `RootView` in ContentView.swift),
    /// which needs a way to finish and move on to sign-in. Left `nil` when reached
    /// from Settings → Onboarding, where the back button is enough.
    var onFinish: (() -> Void)? = nil

    @State private var pageIndex = 0

    private let pages = [
        ("Find your community", "Connect with South Asian neighbors across St. Louis.", "person.3.fill", Theme.Colors.primary),
        ("Share rides safely", "Coordinate cost-sharing rides for airport, campus, temple, and long trips.", "car.fill", Theme.Colors.carpoolAccent),
        ("Buy, sell, and help", "Post housing, jobs, food, services, and events with community trust.", "storefront.fill", Theme.Colors.marketAccent)
    ]

    private var isLastPage: Bool { pageIndex == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            if let onFinish {
                HStack {
                    Spacer()
                    Button("Skip") { onFinish() }
                        .font(.inter(.semibold, size: 14))
                        .foregroundStyle(.secondary)
                        .padding(.trailing, Theme.Spacing.lg)
                        .padding(.top, 8)
                }
            }

            TabView(selection: $pageIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
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
                    .tag(index)
                }
            }
            .tabViewStyle(.page)

            if let onFinish {
                PrimaryButton(isLastPage ? "Get Started" : "Next") {
                    if isLastPage {
                        onFinish()
                    } else {
                        withAnimation { pageIndex += 1 }
                    }
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .appBackground()
        .navigationTitle("Welcome")
    }
}

// MARK: - Delete Account

struct DeleteAccountView: View {
    @Environment(AuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var confirmationText = ""
    @State private var isDeleting = false
    @State private var didFail = false

    private var canDelete: Bool {
        confirmationText.trimmingCharacters(in: .whitespaces).uppercased() == "DELETE" && !isDeleting
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label {
                        Text("Your account will be deactivated immediately.")
                            .font(.inter(.semibold, size: 14))
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.Colors.error)
                    }
                }
                Section {
                    Text("Your listings, ride posts, and profile won't be visible to anyone else right away. We'll keep your data for **30 days** in case you change your mind — just sign back in during that time to restore your account.")
                        .font(.inter(.regular, size: 14))
                        .foregroundStyle(.secondary)
                } header: {
                    Text("30-day grace period")
                }
                Section {
                    ForEach([
                        "Your profile and sign-in are permanently deleted",
                        "Your marketplace listings are permanently deleted",
                        "Your ride posts and bookings are permanently deleted",
                        "Your conversations, messages, and uploaded photos are permanently deleted",
                    ], id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle")
                            .font(.inter(.regular, size: 14))
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("After 30 days")
                } footer: {
                    Text("This step can't be undone.")
                }
                Section {
                    TextField("Type DELETE to confirm", text: $confirmationText)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                } header: {
                    Text("Confirm")
                } footer: {
                    Text("Type DELETE above, then tap Delete Account.")
                }
                Section {
                    Button(role: .destructive) {
                        Task { await deleteAccount() }
                    } label: {
                        HStack {
                            Spacer()
                            if isDeleting {
                                ProgressView()
                            } else {
                                Text("Start 30-Day Deletion")
                            }
                            Spacer()
                        }
                    }
                    .disabled(!canDelete)
                }
            }
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isDeleting)
                }
            }
            .alert("Couldn't delete account", isPresented: $didFail) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(auth.errorMessage ?? "Please check your connection and try again.")
            }
            .interactiveDismissDisabled(isDeleting)
        }
        .presentationDetents([.large])
    }

    private func deleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }
        if await auth.requestAccountDeletion() {
            dismiss()
        } else {
            didFail = true
        }
    }
}

// MARK: - Account Pending Deletion

/// Shown in place of the app's main tabs when the signed-in user has a pending
/// account deletion (`profiles.deleted_at` set) — e.g. they signed back in within
/// the 30-day grace period. See `RootView` in ContentView.swift.
struct AccountPendingDeletionView: View {
    @Environment(AuthService.self) private var auth
    @State private var isRestoring = false
    @State private var isSigningOut = false
    @State private var restoreFailed = false

    private var purgeDate: Date? {
        guard let deletedAt = auth.currentUser?.deletedAt else { return nil }
        return Calendar.current.date(byAdding: .day, value: 30, to: deletedAt)
    }

    private var purgeDateText: String {
        guard let purgeDate else { return "in 30 days" }
        return purgeDate.formatted(date: .long, time: .omitted)
    }

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(Theme.Colors.error)
            Text("Account Scheduled for Deletion")
                .font(.nunito(.black, size: 24))
                .multilineTextAlignment(.center)
            Text("Your account and all its data will be permanently deleted on \(purgeDateText). Restore it now to keep using Milao, or sign out to let deletion continue.")
                .font(.inter(.regular, size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
            VStack(spacing: 12) {
                PrimaryButton("Restore My Account", isLoading: isRestoring) {
                    Task { await restore() }
                }
                SecondaryButton(isSigningOut ? "Signing Out…" : "Sign Out") {
                    Task {
                        isSigningOut = true
                        await auth.signOut()
                    }
                }
                .disabled(isSigningOut)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appBackground()
        .alert("Couldn't restore account", isPresented: $restoreFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(auth.errorMessage ?? "Please check your connection and try again.")
        }
    }

    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        if !(await auth.cancelAccountDeletion()) {
            restoreFailed = true
        }
    }
}

private struct LegalSection: Identifiable {
    let id = UUID()
    let heading: String
    let body: String
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

        fileprivate var sections: [LegalSection] {
            switch self {
            case .privacy:      LegalContent.privacy
            case .terms:        LegalContent.terms
            case .disclaimer:   LegalContent.disclaimer
            }
        }
    }

    let kind: Kind

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(kind.title)
                    .font(.nunito(.black, size: 30))
                ForEach(kind.sections) { section in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(section.heading)
                            .font(.inter(.bold, size: 16))
                        Text(section.body)
                            .font(.inter(.regular, size: 15))
                            .foregroundStyle(.secondary)
                            .lineSpacing(5)
                    }
                }
                Text("Last updated: September 23, 2026")
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

// MARK: - Legal Content
//
// ⚠️ CONTACT_EMAIL below is a placeholder — swap it for a real, monitored address
// (and update it in the App Store Connect "Support URL" / privacy contact fields
// too) before submitting for review. Everything else here describes Milao's
// actual data practices as implemented in this codebase; it is not a substitute
// for review by a lawyer licensed in your state before shipping to real users.

private enum LegalContent {
    static let contactEmail = "support@milaoapp.com"

    static let privacy: [LegalSection] = [
        LegalSection(heading: "Overview", body: """
        This Privacy Policy explains what information Milao ("we," "us," "our") collects through the \
        Milao app, how we use it, and the choices you have. Milao is a community platform for the St. \
        Louis-area South Asian community, covering a classifieds marketplace, ride cost-sharing, and \
        direct messaging between members.
        """),
        LegalSection(heading: "Information You Provide", body: """
        When you create an account, we collect your name, email address, password, and — optionally — \
        your phone number. You may also add a username, bio, city, and profile photo. Anything you post \
        or send through the app — marketplace listings, ride offers and requests, chat messages and \
        photos, ratings, reports, and feedback submissions — is collected and stored so the app can show \
        it to the people you're communicating or transacting with.
        """),
        LegalSection(heading: "Location", body: """
        When you sign up, we request your device's location once to confirm you're within Milao's St. \
        Louis metro service area. We do not track your location in the background, and we do not store \
        your precise coordinates — only the pass/fail result of that check.
        """),
        LegalSection(heading: "Signing In With Apple or Google", body: """
        If you sign in with Apple or Google, we receive your name and email address from that provider, \
        subject to their own privacy policies and whatever sharing preference you chose (e.g. Apple's \
        "Hide My Email"). If you enable Face ID / Touch ID sign-in, your credentials are stored only in \
        your device's secure keychain, protected by your biometrics — they never reach our servers.
        """),
        LegalSection(heading: "What We Don't Collect", body: """
        Milao does not use third-party analytics, advertising, or attribution SDKs of any kind, and we \
        do not collect browsing behavior, ad identifiers, or precise ongoing location. The only \
        third-party service we rely on is Supabase, described below.
        """),
        LegalSection(heading: "How We Use Your Information", body: """
        We use your information to operate the app's features, connect you with other Milao members, \
        confirm you're within our service area, review reports and enforce our Terms & Conditions to \
        keep the community safe, and respond to feedback and support requests.
        """),
        LegalSection(heading: "How We Share Your Information", body: """
        Your profile, listings, ride posts, and messages are visible to other Milao members as a normal \
        part of using the app. We store and process data using Supabase, our backend infrastructure \
        provider, under its own data-processing terms. We do not sell your information, and we do not \
        share it with advertisers.
        """),
        LegalSection(heading: "Data Retention & Account Deletion", body: """
        You can delete your account at any time from Settings → Delete Account. Doing so deactivates it \
        immediately — your listings, ride posts, and profile stop being visible to other members right \
        away. We keep your data for 30 days in case you change your mind; signing back in during that \
        window lets you restore your account. After 30 days, your account and everything tied to it — \
        profile, listings, ride posts, messages, and any photos you uploaded — are permanently and \
        irreversibly deleted.
        """),
        LegalSection(heading: "Children's Privacy", body: """
        Milao is intended for users 13 and older, and we do not knowingly collect information from \
        children under 13. If you believe a child under 13 has created an account, contact us at \
        \(contactEmail) and we will delete it.
        """),
        LegalSection(heading: "Your Choices", body: """
        You can edit or remove your profile information and posts at any time, block or report other \
        members, and delete your account as described above. You can also contact us to ask what \
        information we hold about you.
        """),
        LegalSection(heading: "Security", body: """
        We use reasonable technical and organizational measures — including encrypted connections and \
        password hashing — to protect your information. No method of transmission or storage is \
        completely secure, and we can't guarantee absolute security.
        """),
        LegalSection(heading: "Changes to This Policy", body: """
        If we make material changes to this policy, we'll update the date below. Continuing to use \
        Milao after a change means you accept the updated policy.
        """),
        LegalSection(heading: "Contact Us", body: """
        Questions about this policy or your data? Email us at \(contactEmail).
        """),
    ]

    static let terms: [LegalSection] = [
        LegalSection(heading: "Acceptance of Terms", body: """
        By creating a Milao account or using the app, you agree to these Terms & Conditions and to our \
        Privacy Policy and Disclaimer. If you don't agree, please don't use Milao.
        """),
        LegalSection(heading: "Eligibility", body: """
        You must be at least 13 years old to create a Milao account. If you're under 18, you confirm you \
        have any permission required by law to use the app. Some features, including ride posts, may ask \
        you to separately attest to a minimum age before you can use them.
        """),
        LegalSection(heading: "Your Account", body: """
        You're responsible for the accuracy of the information on your account and for keeping your \
        credentials secure. Each person may keep only one account. Tell us right away if you suspect \
        unauthorized use of your account.
        """),
        LegalSection(heading: "Content You Post", body: """
        You're solely responsible for anything you post — listings, ride offers and requests, messages, \
        photos, ratings, and reports — and you confirm you have the right to post it. By posting, you \
        grant Milao a non-exclusive, royalty-free license to host and display that content within the \
        app so other members can see it.
        """),
        LegalSection(heading: "Marketplace & Rides Are Peer-to-Peer", body: """
        Milao provides a place for members to post and discover listings and ride cost-sharing \
        opportunities. We are not a party to any transaction or ride arrangement between members — we \
        don't buy, sell, ship, inspect, or take title to any goods listed, and we are not a \
        transportation carrier, broker, or employer. You are solely responsible for evaluating other \
        members and for your own safety when meeting up or coordinating with them.
        """),
        LegalSection(heading: "Prohibited Conduct", body: """
        Don't use Milao to post anything illegal, fraudulent, or misleading; to harass, threaten, or \
        impersonate anyone; to spam other members; or to try to circumvent the app's safety or \
        moderation features.
        """),
        LegalSection(heading: "Reporting & Moderation", body: """
        Milao lets members report listings, ride posts, and other users. We may review reported content, \
        remove content, or suspend or terminate accounts that violate these Terms, at our discretion.
        """),
        LegalSection(heading: "Ending Your Account", body: """
        You may delete your account at any time in Settings — see the Privacy Policy for how that works. \
        We may also suspend or terminate accounts that violate these Terms.
        """),
        LegalSection(heading: "Disclaimers", body: """
        Milao is provided "as is" and "as available," without warranties of any kind, to the fullest \
        extent permitted by law.
        """),
        LegalSection(heading: "Limitation of Liability", body: """
        To the fullest extent permitted by law, Milao is not liable for indirect, incidental, or \
        consequential damages, for disputes between members, or for the conduct of any member, whether \
        online or in person.
        """),
        LegalSection(heading: "Governing Law", body: """
        These Terms are governed by the laws of the State of Missouri, without regard to conflict-of-law \
        principles.
        """),
        LegalSection(heading: "Changes to These Terms", body: """
        If we make material changes, we'll update the date below. Continuing to use Milao after a change \
        means you accept the updated Terms.
        """),
        LegalSection(heading: "Contact Us", body: """
        Questions about these Terms? Email us at \(contactEmail).
        """),
    ]

    static let disclaimer: [LegalSection] = [
        LegalSection(heading: "A Community Platform, Not a Marketplace Operator", body: """
        Milao is a place for the St. Louis-area community to post and discover listings for housing, \
        jobs, items for sale, and food. We are not the seller, landlord, employer, or vendor behind any \
        listing, and we don't handle payments between members — those arrangements are strictly between \
        the members involved.
        """),
        LegalSection(heading: "Not a Transportation Company", body: """
        Milao's ride feature connects members who want to share the cost of a ride. Milao is not a \
        transportation network company, taxi service, or broker, does not employ or vet drivers, and is \
        not a party to any ride arrangement. Riders and drivers coordinate and travel at their own \
        discretion and risk.
        """),
        LegalSection(heading: "We Don't Vet Members or Content", body: """
        Milao does not conduct background checks on members and does not verify the accuracy of \
        listings, ride posts, or messages. Ratings and reports are provided by other members, not by \
        Milao, and should inform — not replace — your own judgment. Meet in public places when possible, \
        and use caution before sharing personal information or exchanging money.
        """),
        LegalSection(heading: "No Endorsement", body: """
        Listings, ride posts, and other content on Milao reflect the views of the members who posted \
        them, not Milao's. Their presence on the app is not an endorsement or a guarantee of accuracy, \
        safety, or legality.
        """),
    ]
}
