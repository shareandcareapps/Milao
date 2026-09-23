import Foundation
import Supabase

@Observable
@MainActor
final class MessagesService {
    var conversations: [Conversation] = []
    var messages: [Message] = []
    var isLoading = false
    var error: String?
    var unreadCount = 0

    private var realtimeChannel: RealtimeChannelV2?
    private static let iso8601 = ISO8601DateFormatter()

    // MARK: - Conversations

    func fetchConversations(userId: UUID) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let raw: [Conversation] = try await supabase
                .from("conversations")
                .select()
                .or("participant_1.eq.\(userId.uuidString),participant_2.eq.\(userId.uuidString)")
                .order("last_message_at", ascending: false)
                .execute()
                .value

            // Enrich with other-participant profiles
            let otherIds = raw.map { $0.otherUserId(myId: userId) }
            let uniqueIds = Array(Set(otherIds))

            let profiles: [OtherProfile] = (try? await supabase
                .from("profiles")
                .select("id, username, avatar_url")
                .in("id", values: uniqueIds.map { $0.uuidString })
                .execute()
                .value) ?? []

            let profileMap = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })

            // Fetch unread counts for all conversations in one query.
            let convIds = raw.map { $0.id.uuidString }
            var unreadMap: [UUID: Int] = [:]
            if !convIds.isEmpty {
                let unreadRows: [[String: AnyJSON]] = (try? await supabase
                    .from("messages")
                    .select("conversation_id")
                    .neq("is_read", value: true)
                    .neq("sender_id", value: userId.uuidString)
                    .in("conversation_id", values: convIds)
                    .execute()
                    .value) ?? []
                for row in unreadRows {
                    if case .string(let cid) = row["conversation_id"], let uuid = UUID(uuidString: cid) {
                        unreadMap[uuid, default: 0] += 1
                    }
                }
            }

            conversations = raw.map { conv in
                var c = conv
                c.otherProfile = profileMap[c.otherUserId(myId: userId)]
                c.unreadCount = unreadMap[c.id]
                return c
            }
            unreadCount = unreadMap.values.filter { $0 > 0 }.count
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Get or create conversation

    func getOrCreate(myId: UUID, otherUserId: UUID, listingId: UUID? = nil, listingTitle: String? = nil, rideId: UUID? = nil) async throws -> Conversation {
        let type = listingId != nil ? "listing" : (rideId != nil ? "ride" : "direct")

        // Check if exists
        var query = supabase
            .from("conversations")
            .select()
            .or("and(participant_1.eq.\(myId.uuidString),participant_2.eq.\(otherUserId.uuidString)),and(participant_1.eq.\(otherUserId.uuidString),participant_2.eq.\(myId.uuidString))")

        if let lid = listingId {
            query = query.eq("listing_id", value: lid.uuidString)
        }

        let existing: [Conversation] = (try? await query.limit(1).execute().value) ?? []
        if let conv = existing.first { return conv }

        // Create new
        var payload: [String: AnyJSON] = [
            "participant_1": .string(myId.uuidString),
            "participant_2": .string(otherUserId.uuidString),
            "type":          .string(type),
        ]
        if let lid = listingId { payload["listing_id"]    = .string(lid.uuidString) }
        if let lt  = listingTitle { payload["listing_title"] = .string(lt) }
        if let rid = rideId    { payload["ride_id"]       = .string(rid.uuidString) }

        return try await supabase
            .from("conversations")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Messages

    func fetchMessages(conversationId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            messages = try await supabase
                .from("messages")
                .select()
                .eq("conversation_id", value: conversationId.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value
        } catch {
            self.error = error.localizedDescription
        }
    }

    func sendMessage(conversationId: UUID, senderId: UUID, body: String) async throws {
        let payload: [String: AnyJSON] = [
            "conversation_id": .string(conversationId.uuidString),
            "sender_id":       .string(senderId.uuidString),
            "body":            .string(body),
            "is_read":         .bool(false),
        ]
        let msg: Message = try await supabase
            .from("messages")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
        messages.append(msg)

        // Update conversation last_message
        _ = try? await supabase
            .from("conversations")
            .update([
                "last_message":    AnyJSON.string(body),
                "last_message_at": AnyJSON.string(MessagesService.iso8601.string(from: Date())),
            ])
            .eq("id", value: conversationId.uuidString)
            .execute()
    }

    func markRead(conversationId: UUID, userId: UUID) async {
        _ = try? await supabase
            .from("messages")
            .update(["is_read": true])
            .eq("conversation_id", value: conversationId.uuidString)
            .neq("sender_id", value: userId.uuidString)
            .neq("is_read", value: true)
            .execute()
    }

    // MARK: - Reactions

    func addReaction(messageId: UUID, userId: UUID, emoji: String) async throws {
        let payload: [String: AnyJSON] = [
            "message_id": .string(messageId.uuidString),
            "user_id":    .string(userId.uuidString),
            "emoji":      .string(emoji),
        ]
        do {
            try await supabase.from("message_reactions").insert(payload).execute()
        } catch let error as PostgrestError where error.code == "23505" {
            // Already reacted — ignore duplicate
        }
    }

    func removeReaction(messageId: UUID, userId: UUID, emoji: String) async throws {
        try await supabase
            .from("message_reactions")
            .delete()
            .eq("message_id", value: messageId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .eq("emoji", value: emoji)
            .execute()
    }

    func fetchReactions(messageIds: [UUID]) async -> [UUID: [String: Int]] {
        guard !messageIds.isEmpty else { return [:] }
        guard let rows: [[String: AnyJSON]] = try? await supabase
            .from("message_reactions")
            .select("message_id, emoji, user_id")
            .in("message_id", values: messageIds.map { $0.uuidString })
            .execute()
            .value
        else { return [:] }

        var result: [UUID: [String: Int]] = [:]
        for row in rows {
            guard case .string(let mid) = row["message_id"],
                  case .string(let emoji) = row["emoji"],
                  let uuid = UUID(uuidString: mid) else { continue }
            result[uuid, default: [:]][emoji, default: 0] += 1
        }
        return result
    }

    // MARK: - Unread count

    func refreshUnreadCount(userId: UUID) async {
        // Single query: RLS ensures only messages from the user's own
        // conversations are returned, so no need to pre-fetch conversation IDs.
        let msgs: [[String: AnyJSON]] = (try? await supabase
            .from("messages")
            .select("conversation_id")
            .neq("is_read", value: true)
            .neq("sender_id", value: userId.uuidString)
            .execute()
            .value) ?? []

        unreadCount = Set(msgs.compactMap { row -> String? in
            if case .string(let id) = row["conversation_id"] { return id }
            return nil
        }).count
    }

    // MARK: - Realtime

    func subscribeToMessages(conversationId: UUID) {
        Task {
            await unsubscribe()
            let channel = supabase.realtimeV2.channel("chat-\(conversationId.uuidString)")
            _ = channel.onPostgresChange(
                InsertAction.self,
                schema: "public",
                table: "messages",
                filter: "conversation_id=eq.\(conversationId.uuidString)"
            ) { action in
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .iso8601
                if let newMsg = try? action.decodeRecord(as: Message.self, decoder: decoder) {
                    Task { @MainActor [weak self = self] in
                        guard let self else { return }
                        if !self.messages.contains(where: { $0.id == newMsg.id }) {
                            self.messages.append(newMsg)
                        }
                    }
                }
            }
            realtimeChannel = channel
            try? await channel.subscribeWithError()
        }
    }

    func unsubscribe() async {
        if let ch = realtimeChannel {
            await supabase.realtimeV2.removeChannel(ch)
            realtimeChannel = nil
        }
    }
}
