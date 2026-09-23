import SwiftUI

struct MessagesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(MessagesService.self) private var messagesService
    @Environment(AuthService.self) private var auth
    @State private var selectedFilter: MessageFilter = .all
    @State private var searchText = ""
    @State private var showSearch = false
    @FocusState private var isSearchFocused: Bool

    private var isDark: Bool { colorScheme == .dark }

    private var conversations: [Conversation] {
        messagesService.conversations.filter { conversation in
            let matchesFilter: Bool = switch selectedFilter {
            case .all:         true
            case .classifieds: conversation.type == "listing"
            case .rides:       conversation.type == "ride"
            }
            let matchesSearch = searchText.isEmpty
                || (conversation.otherProfile?.displayName.localizedCaseInsensitiveContains(searchText) ?? false)
                || (conversation.listingTitle?.localizedCaseInsensitiveContains(searchText) ?? false)
                || (conversation.lastMessage?.localizedCaseInsensitiveContains(searchText) ?? false)
            return matchesFilter && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    messagesHeader

                    if showSearch {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Theme.Colors.textSecondary)
                            TextField("Search conversations…", text: $searchText)
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
                        if auth.currentUser == nil {
                            VStack(spacing: 16) {
                                EmptyStateView(
                                    icon: "person.crop.circle.badge.questionmark",
                                    title: "Sign in to message",
                                    message: "Create a free account to chat with sellers, drivers, and riders."
                                )
                                Button("Sign In") {
                                    Task { await auth.signOut() }
                                }
                                .buttonStyle(.glass)
                            }
                            .padding(.top, 60)
                        } else if messagesService.isLoading && messagesService.conversations.isEmpty {
                            ProgressView().padding(.top, 60)
                        } else if messagesService.error != nil && messagesService.conversations.isEmpty {
                            LoadFailedView {
                                if let myId = auth.currentUser?.id {
                                    Task { await messagesService.fetchConversations(userId: myId) }
                                }
                            }
                            .padding(.top, 60)
                        } else if conversations.isEmpty {
                            EmptyStateView(
                                icon: "bubble.left.and.bubble.right",
                                title: "No messages yet",
                                message: "Conversations with sellers, drivers, and riders show up here."
                            )
                            .padding(.top, 60)
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(conversations) { conversation in
                                    if let myId = auth.currentUser?.id {
                                        NavigationLink(destination: ChatView(conversation: conversation, myId: myId)) {
                                            ConversationRow(conversation: conversation, myId: myId)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.bottom, 100)
                        }
                    }
                    .refreshable {
                        if let myId = auth.currentUser?.id {
                            await messagesService.fetchConversations(userId: myId)
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .animation(.spring(response: 0.3, dampingFraction: 0.82), value: showSearch)
            .task {
                if let myId = auth.currentUser?.id {
                    await messagesService.fetchConversations(userId: myId)
                }
            }
        }
    }

    private var messagesHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Messages")
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

            HStack(spacing: 8) {
                ForEach(MessageFilter.allCases) { filter in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.86)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.title)
                            .font(Theme.Fonts.nunitoBold(size: 12))
                            .foregroundStyle(selectedFilter == filter ? Theme.Colors.primary : .white.opacity(0.70))
                            .padding(.horizontal, 12)
                            .frame(height: 30)
                            .background(
                                Capsule()
                                    .fill(selectedFilter == filter ? Color.white : Color.white.opacity(0.14))
                                    .overlay(Capsule().stroke(Color.white.opacity(selectedFilter == filter ? 0 : 0.28), lineWidth: 1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
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

private enum MessageFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case classifieds = "Classifieds"
    case rides = "Rides"

    var id: String { rawValue }
    var title: String { rawValue }
}

private struct ConversationRow: View {
    let conversation: Conversation
    let myId: UUID

    private var name: String { conversation.otherProfile?.displayName ?? "User" }
    private var subject: String { conversation.listingTitle ?? (conversation.rideId != nil ? "Carpool" : "Direct message") }
    private var typeColor: Color { conversation.type == "ride" ? Theme.Colors.carpoolAccent : Theme.Colors.accent }
    private var typeIcon: String { conversation.type == "ride" ? "car.fill" : "tag.fill" }
    private var preview: String { conversation.lastMessage ?? "Say hello 👋" }
    private var timestamp: String {
        guard let date = conversation.lastMessageAt else { return "" }
        return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }
    private var hasUnread: Bool { (conversation.unreadCount ?? 0) > 0 }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                Text(String(name.prefix(1)))
                    .font(Theme.Fonts.nunitoExtraBold(size: 15))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        LinearGradient(colors: Theme.Colors.primaryGradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: Circle()
                    )

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(name)
                            .font(Theme.Fonts.nunitoExtraBold(size: 15))
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: 3) {
                            Image(systemName: typeIcon)
                                .font(.system(size: 9, weight: .bold))
                            Text(subject)
                                .lineLimit(1)
                        }
                        .font(Theme.Fonts.nunitoBold(size: 10))
                        .foregroundStyle(typeColor)
                        .padding(.horizontal, 7)
                        .frame(height: 18)
                        .background(typeColor.opacity(0.12), in: Capsule())

                        Spacer(minLength: 4)

                        Text(timestamp)
                            .font(Theme.Fonts.interRegular(size: 11))
                            .foregroundStyle(Theme.Colors.textLight)
                    }

                    HStack {
                        Text(preview)
                            .font(Theme.Fonts.interRegular(size: 13))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .lineLimit(1)
                        if hasUnread {
                            Spacer(minLength: 4)
                            Circle().fill(Theme.Colors.primary).frame(width: 8, height: 8)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.screen)
            .padding(.vertical, 14)
            .background(Theme.Colors.card)

            Divider()
                .padding(.leading, Theme.Spacing.screen + 42 + 14)
        }
    }
}
