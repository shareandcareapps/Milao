import SwiftUI

struct MessagesView: View {
    @State private var selectedFilter: MessageFilter = .all

    private var conversations: [CommunityConversation] {
        CommunitySamples.conversations.filter { conversation in
            selectedFilter == .all || conversation.subject.localizedCaseInsensitiveContains(selectedFilter.rawValue)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messagesHeader

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(conversations) { conversation in
                            NavigationLink(destination: ChatView(conversation: conversation)) {
                                ConversationRow(conversation: conversation)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 120)
                }
                .background(Theme.Colors.background)
            }
            .ignoresSafeArea(edges: .top)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var messagesHeader: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack {
                Text("Messages")
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

            HStack(spacing: 12) {
                ForEach(MessageFilter.allCases) { filter in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.86)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.title)
                            .font(Theme.Fonts.nunitoBold(size: 15))
                            .foregroundStyle(selectedFilter == filter ? Theme.Colors.primary : Theme.Colors.textLight)
                            .padding(.horizontal, 18)
                            .frame(height: 44)
                            .background(
                                Capsule()
                                    .fill(selectedFilter == filter ? Theme.Colors.white : Theme.Colors.white.opacity(0.24))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .padding(.bottom, 22)
        .background(
            LinearGradient(colors: Theme.Colors.headerGradientLight, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)
        )
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
    let conversation: CommunityConversation

    private var typeColor: Color {
        conversation.tint
    }

    private var typeIcon: String {
        conversation.subject.localizedCaseInsensitiveContains("ride") || conversation.subject.localizedCaseInsensitiveContains("airport") ? "car.fill" : "tag.fill"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            Text(String(conversation.name.prefix(1)))
                .font(Theme.Fonts.nunitoExtraBold(size: 18))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(colors: Theme.Colors.primaryGradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Circle()
                )

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text(conversation.name)
                        .font(Theme.Fonts.nunitoExtraBold(size: 22))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        Image(systemName: typeIcon)
                            .font(.system(size: 11, weight: .bold))
                        Text(conversation.subject)
                            .lineLimit(1)
                    }
                    .font(Theme.Fonts.nunitoBold(size: 11))
                    .foregroundStyle(typeColor)
                    .padding(.horizontal, 9)
                    .frame(height: 24)
                    .background(typeColor.opacity(0.12), in: Capsule())

                    Spacer(minLength: 6)

                    Text(conversation.timestamp)
                        .font(Theme.Fonts.interRegular(size: 13))
                        .foregroundStyle(Theme.Colors.textLight)
                }

                Text("You: \(conversation.preview)")
                    .font(Theme.Fonts.interRegular(size: 15))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.vertical, 16)
        .background(Theme.Colors.card)
    }
}

struct ChatView: View {
    let conversation: CommunityConversation
    @State private var messageText = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(CommunitySamples.chatMessages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
                .background(Theme.Colors.background)
                .onAppear {
                    if let last = CommunitySamples.chatMessages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            HStack(spacing: 12) {
                TextField("Message", text: $messageText, axis: .vertical)
                    .font(Theme.Fonts.interRegular(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Theme.Colors.inputBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                Button {
                    messageText = ""
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(messageText.isEmpty ? Theme.Colors.textLight : Theme.Colors.primary, in: Circle())
                }
                .disabled(messageText.isEmpty)
            }
            .padding(16)
            .background(.regularMaterial)
        }
        .navigationTitle(conversation.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MessageBubble: View {
    let message: CommunityMessage

    var body: some View {
        HStack {
            if message.isMine { Spacer(minLength: 48) }

            VStack(alignment: message.isMine ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(Theme.Fonts.interRegular(size: 16))
                    .foregroundStyle(message.isMine ? .white : Theme.Colors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.isMine ? Theme.Colors.primary : Theme.Colors.card,
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )

                Text(message.timestamp)
                    .font(Theme.Fonts.interRegular(size: 12))
                    .foregroundStyle(Theme.Colors.textLight)
            }

            if !message.isMine { Spacer(minLength: 48) }
        }
    }
}
