import SwiftUI
import PhotosUI
import Supabase

struct ChatView: View {
    let conversation: Conversation
    let myId: UUID

    @Environment(MessagesService.self) private var service
    @Environment(AuthService.self) private var auth
    @Environment(BlockedUsersService.self) private var blockedUsersService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var safeAreaTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
    }

    @State private var messageText = ""
    @State private var isSending = false
    @State private var reactionTarget: Message? = nil
    @State private var photosItem: PhotosPickerItem? = nil
    @State private var isUploadingImage = false
    @State private var reactions: [UUID: [String: Int]] = [:]
    @State private var showReport = false
    @State private var isBlocked = false
    @State private var isUpdatingBlock = false
    @State private var actionFailed = false

    private var otherName: String { conversation.otherProfile?.displayName ?? "Chat" }
    private var convId: UUID { conversation.id }
    private var otherUserId: UUID { conversation.otherUserId(myId: myId) }
    private var otherAvatarURL: String? { conversation.otherProfile?.avatarURL }

    var body: some View {
        VStack(spacing: 0) {
            chatNavBar
            messagesArea
            if isBlocked {
                blockedBanner
            } else {
                composerBar
            }
        }
        .background(chatBackground)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await service.fetchMessages(conversationId: convId)
            service.subscribeToMessages(conversationId: convId)
            await service.markRead(conversationId: convId, userId: myId)
            let ids = service.messages.map { $0.id }
            if !ids.isEmpty { reactions = await service.fetchReactions(messageIds: ids) }
            isBlocked = await blockedUsersService.isBlocked(blockerId: myId, blockedId: otherUserId)
        }
        .onChange(of: service.messages.count) { _, _ in
            Task {
                let ids = service.messages.map { $0.id }
                if !ids.isEmpty { reactions = await service.fetchReactions(messageIds: ids) }
            }
        }
        .onDisappear { Task { await service.unsubscribe() } }
        .sheet(isPresented: $showReport) {
            ReportSheet(reporterId: myId, reportedUserId: conversation.otherUserId(myId: myId))
        }
        .sheet(item: $reactionTarget) { msg in
            EmojiPickerSheet { emoji in
                Task { try? await service.addReaction(messageId: msg.id, userId: myId, emoji: emoji) }
                reactionTarget = nil
            }
        }
        .alert("Something went wrong", isPresented: $actionFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please check your connection and try again.")
        }
    }

    // MARK: - Background

    private var chatBackground: Color {
        colorScheme == .dark ? Color(hex: "#1A1A1A") : Color(hex: "#F2F2F7")
    }

    // MARK: - Nav Bar (PDF: gradientHeader, chevron.left, AvatarView 40x40, name 15pt Nunito 700, subtitle 11pt)

    private var chatNavBar: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Back")

            InitialsAvatar(name: otherName, color: Theme.Colors.primary, size: 40, imageURL: otherAvatarURL)

            VStack(alignment: .leading, spacing: 2) {
                Text(otherName)
                    .font(.nunito(.bold, size: 15))
                    .foregroundStyle(.white)
                if let ctx = conversation.listingTitle ?? (conversation.rideId != nil ? "Carpool" : nil) {
                    Text(ctx)
                        .font(.inter(.regular, size: 11))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }

            Spacer()

            Menu {
                Button(role: .destructive) {
                    Task { await toggleBlock() }
                } label: {
                    if isBlocked {
                        Label("Unblock user", systemImage: "person.crop.circle.badge.checkmark")
                    } else {
                        Label("Block user", systemImage: "person.crop.circle.badge.xmark")
                    }
                }
                Button(role: .destructive) { showReport = true } label: {
                    Label("Report user", systemImage: "flag")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 56)
        .padding(.top, safeAreaTop)
        .background(
            // Matches the app-wide header treatment: navy in light, neutral dark gradient in dark
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(hex: "#2B2B2B"), Color(hex: "#171717")]
                    : [Color(hex: "#0A2463"), Color(hex: "#132F7A")],
                startPoint: .top, endPoint: .bottom
            )
        )
        .overlay(alignment: .bottom) {
            Rectangle().fill(.white.opacity(0.15)).frame(height: 0.5)
        }
    }

    // MARK: - Messages Area

    private var messagesArea: some View {
        Group {
            if service.isLoading && service.messages.isEmpty {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if service.error != nil && service.messages.isEmpty {
                LoadFailedView {
                    Task { await service.fetchMessages(conversationId: convId) }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if service.messages.isEmpty {
                EmptyStateView(icon: "bubble.left", title: "Say hello 👋", message: "Start the conversation.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(service.messages) { msg in
                                MessageBubble(
                                    message: msg,
                                    isMine: msg.senderId == myId,
                                    reactions: reactions[msg.id] ?? [:]
                                )
                                .id(msg.id)
                                .onLongPressGesture { reactionTarget = msg }
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .onChange(of: service.messages.count) { _, _ in
                        if let last = service.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Composer

    private var composerBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            let uploading = isUploadingImage
            PhotosPicker(selection: $photosItem, matching: .images) {
                Image(systemName: uploading ? "arrow.up.circle.fill" : "photo.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.Colors.primary)
                    .frame(width: 36, height: 36)
            }
            .onChange(of: photosItem) { _, item in
                guard let item else { return }
                Task { await uploadPhoto(item) }
            }

            HStack(alignment: .bottom, spacing: 0) {
                TextField("Message", text: $messageText, axis: .vertical)
                    .font(.inter(.regular, size: 15))
                    .foregroundStyle(.primary)
                    .tint(Theme.Colors.primary)
                    .lineLimit(5)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
            .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.Colors.border, lineWidth: 1))

            // Send button — PDF: 40×40 circle gradient #E8185C→#FF5580, paperplane.fill 18pt
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                Task { await send() }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? Theme.Colors.primaryGradient.map { $0.opacity(0.3) }
                                    : Theme.Colors.primaryGradient,
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    if isSending {
                        ProgressView().tint(.white).scaleEffect(0.8)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .padding(.bottom, 4)
        .background(Theme.Colors.card)
        .overlay(alignment: .top) { Divider() }
    }

    // MARK: - Blocked banner

    private var blockedBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.xmark")
                .foregroundStyle(Theme.Colors.textSecondary)
            Text("You've blocked \(otherName). They can't message you.")
                .font(.inter(.regular, size: 13))
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
            Button(isUpdatingBlock ? "…" : "Unblock") {
                Task { await toggleBlock() }
            }
            .font(.inter(.semibold, size: 13))
            .disabled(isUpdatingBlock)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.Colors.card)
        .overlay(alignment: .top) { Divider() }
    }

    // MARK: - Actions

    private func toggleBlock() async {
        isUpdatingBlock = true
        defer { isUpdatingBlock = false }
        do {
            if isBlocked {
                try await blockedUsersService.unblock(blockerId: myId, blockedId: otherUserId)
            } else {
                try await blockedUsersService.block(blockerId: myId, blockedId: otherUserId)
            }
            isBlocked.toggle()
        } catch {
            actionFailed = true
        }
    }

    private func send() async {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSending = true
        messageText = ""
        do {
            try await service.sendMessage(conversationId: convId, senderId: myId, body: trimmed)
        } catch {
            messageText = trimmed
            actionFailed = true
        }
        isSending = false
    }

    @MainActor
    private func uploadPhoto(_ item: PhotosPickerItem) async {
        isUploadingImage = true
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let path = "chat/\(convId.uuidString)_\(Int(Date().timeIntervalSince1970)).jpg"
                let bucket = supabase.storage.from("listings")
                _ = try await bucket.upload(path, data: data, options: .init(contentType: "image/jpeg"))
                let publicURL = try bucket.getPublicURL(path: path)
                let body = "[image]:\(publicURL.absoluteString)"
                try await service.sendMessage(conversationId: convId, senderId: myId, body: body)
            }
        } catch {
            actionFailed = true
        }
        photosItem = nil
        isUploadingImage = false
    }
}

// MARK: - Message Bubble (WhatsApp style)

private struct MessageBubble: View {
    let message: Message
    let isMine: Bool
    let reactions: [String: Int]
    @Environment(\.colorScheme) private var colorScheme

    private var bubbleColor: Color {
        isMine
            ? Theme.Colors.primary
            : (colorScheme == .dark ? Color(hex: "#2A2A2A") : .white)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isMine { Spacer(minLength: 56) }

            VStack(alignment: isMine ? .trailing : .leading, spacing: 3) {
                // Bubble — UnevenRoundedRectangle per PDF spec
                bubbleContent
                    .background(bubbleColor)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 18,
                            bottomLeadingRadius: isMine ? 18 : 4,
                            bottomTrailingRadius: isMine ? 4 : 18,
                            topTrailingRadius: 18,
                            style: .continuous
                        )
                    )
                    .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)

                // Reactions
                if !reactions.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(reactions.keys.sorted(), id: \.self) { emoji in
                            Text("\(emoji)\(reactions[emoji]!)")
                                .font(.system(size: 13))
                                .padding(.horizontal, 7).padding(.vertical, 2)
                                .background(Color.black.opacity(0.07), in: Capsule())
                        }
                    }
                }

                // Time + ticks
                HStack(spacing: 3) {
                    Text(message.formattedTime)
                        .font(.inter(.regular, size: 10))
                        .foregroundStyle(Theme.Colors.textLight)
                    if isMine {
                        Image(systemName: "checkmark.message")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.Colors.primary.opacity(0.8))
                    }
                }
            }

            if !isMine { Spacer(minLength: 56) }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 1)
    }

    @ViewBuilder
    private var bubbleContent: some View {
        switch message.content {
        case .text(let text):
            Text(text)
                .font(.inter(.regular, size: 15))
                .foregroundStyle(isMine ? .white : Theme.Colors.textPrimary)
                .lineSpacing(3)
                .padding(.horizontal, 13).padding(.vertical, 9)
                .padding(.trailing, isMine ? 4 : 0)
                .padding(.leading, isMine ? 0 : 4)

        case .image(let url):
            AsyncImage(url: url) { img in
                img.resizable().scaledToFill()
                    .frame(maxWidth: 220, maxHeight: 220)
                    .clipped()
            } placeholder: {
                Color.gray.opacity(0.15).frame(width: 200, height: 160)
                    .overlay(ProgressView())
            }
            .padding(4)

        case .location(let lat, let lng, let address):
            VStack(alignment: .leading, spacing: 5) {
                Label(address, systemImage: "mappin.circle.fill")
                    .font(.inter(.medium, size: 13))
                    .foregroundStyle(isMine ? .white : Theme.Colors.textPrimary)
                    .lineLimit(2)
                Text("\(String(format: "%.4f", lat)), \(String(format: "%.4f", lng))")
                    .font(.inter(.regular, size: 11))
                    .foregroundStyle(isMine ? .white.opacity(0.7) : Theme.Colors.textLight)
            }
            .padding(.horizontal, 13).padding(.vertical, 9)
        }
    }
}

// MARK: - Emoji Picker Sheet

private struct EmojiPickerSheet: View {
    let onPick: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    private let emojis = ["👍","❤️","😂","😮","😢","🙏","🔥","👏","😍","🤔"]

    var body: some View {
        VStack(spacing: 20) {
            Text("React")
                .font(.inter(.bold, size: 16))
                .foregroundStyle(Theme.Colors.textPrimary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                ForEach(emojis, id: \.self) { e in
                    Button {
                        onPick(e)
                        dismiss()
                    } label: {
                        Text(e).font(.system(size: 32))
                    }
                }
            }
        }
        .padding(24)
        .presentationDetents([.height(180)])
    }
}

// MARK: - Message helpers

extension Message {
    var formattedTime: String {
        let fmt = DateFormatter()
        fmt.dateFormat = Date().timeIntervalSince(createdAt) < 86400 ? "h:mm a" : "MMM d"
        return fmt.string(from: createdAt)
    }
}
