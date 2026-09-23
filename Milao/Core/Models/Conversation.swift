import Foundation

// MARK: - Conversation (matches `conversations` Supabase table)

struct Conversation: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    var participant1: UUID
    var participant2: UUID
    var listingId: UUID?
    var listingTitle: String?
    var rideId: UUID?
    var type: String              // listing | ride | direct
    var lastMessage: String?
    var lastMessageAt: Date?
    var contextDate: String?
    var createdAt: Date

    // Enriched client-side (not in DB)
    var otherProfile: OtherProfile?
    var listingImage: String?
    var unreadCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, type
        case participant1  = "participant_1"
        case participant2  = "participant_2"
        case listingId     = "listing_id"
        case listingTitle  = "listing_title"
        case rideId        = "ride_id"
        case lastMessage   = "last_message"
        case lastMessageAt = "last_message_at"
        case contextDate   = "context_date"
        case createdAt     = "created_at"
    }

    func otherUserId(myId: UUID) -> UUID {
        participant1 == myId ? participant2 : participant1
    }
}

// MARK: - Other participant profile (fetched separately)

struct OtherProfile: Codable, Sendable, Hashable {
    var id: UUID
    var username: String?
    var avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case avatarURL = "avatar_url"
    }

    var displayName: String { username ?? "User" }
}

// MARK: - Message (matches `messages` Supabase table)

struct Message: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    var conversationId: UUID
    var senderId: UUID
    var body: String
    var isRead: Bool
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, body
        case conversationId = "conversation_id"
        case senderId       = "sender_id"
        case isRead         = "is_read"
        case createdAt      = "created_at"
    }

    // MARK: - Message format parsing (per spec §7)

    enum Content {
        case text(String)
        case image(URL)
        case location(lat: Double, lng: Double, address: String)
    }

    var content: Content {
        if body.hasPrefix("[image]:") {
            let urlString = String(body.dropFirst("[image]:".count))
            if let url = URL(string: urlString) { return .image(url) }
        }
        if body.hasPrefix("[location]:") {
            let rest = String(body.dropFirst("[location]:".count))
            let parts = rest.split(separator: ":", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                let coords = parts[0].split(separator: ",").map(String.init)
                if coords.count == 2,
                   let lat = Double(coords[0]), let lng = Double(coords[1]) {
                    return .location(lat: lat, lng: lng, address: parts[1])
                }
            }
        }
        return .text(body)
    }

    var previewText: String {
        switch content {
        case .text(let t):              return t
        case .image:                    return "📷 Photo"
        case .location(_, _, let addr): return "📍 \(addr)"
        }
    }
}

// MARK: - Message Reaction

struct MessageReaction: Codable, Identifiable, Sendable {
    let id: UUID
    var messageId: UUID
    var userId: UUID
    var emoji: String

    enum CodingKeys: String, CodingKey {
        case id, emoji
        case messageId = "message_id"
        case userId    = "user_id"
    }
}
