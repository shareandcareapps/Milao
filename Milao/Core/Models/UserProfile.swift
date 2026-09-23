import Foundation

struct UserProfile: Codable, Identifiable, Sendable {
    let id: UUID
    var fullName: String
    var username: String?
    var avatarURL: String?
    var bio: String?
    var city: String?
    var phone: String?
    var points: Int
    var role: String?
    var reputationTier: ReputationTier
    var isSuspended: Bool
    var createdAt: Date
    var deletedAt: Date?

    var isAdmin: Bool { role == "admin" }
    /// Account deletion was requested and is pending; purged automatically 30 days after `deletedAt`.
    var isPendingDeletion: Bool { deletedAt != nil }

    enum ReputationTier: String, Codable, Sendable {
        case bronze, silver, gold, platinum, diamond

        var label: String {
            switch self {
            case .bronze:   "Bronze"
            case .silver:   "Silver"
            case .gold:     "Gold"
            case .platinum: "Platinum"
            case .diamond:  "Diamond"
            }
        }

        var icon: String {
            switch self {
            case .bronze:   "🥉"
            case .silver:   "🥈"
            case .gold:     "🥇"
            case .platinum: "💎"
            case .diamond:  "⭐"
            }
        }
    }

    // Maps camelCase Swift properties to snake_case Supabase column names
    enum CodingKeys: String, CodingKey {
        case id, username, bio, city, phone, points, role
        case fullName       = "full_name"
        case avatarURL      = "avatar_url"
        case reputationTier = "reputation_tier"
        case isSuspended    = "suspended"
        case createdAt      = "created_at"
        case deletedAt      = "deleted_at"
    }

    init(
        id: UUID,
        fullName: String,
        username: String? = nil,
        avatarURL: String? = nil,
        bio: String? = nil,
        city: String? = nil,
        phone: String? = nil,
        points: Int = 0,
        role: String? = nil,
        reputationTier: ReputationTier = .bronze,
        isSuspended: Bool = false,
        createdAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.fullName = fullName
        self.username = username
        self.avatarURL = avatarURL
        self.bio = bio
        self.city = city
        self.phone = phone
        self.points = points
        self.role = role
        self.reputationTier = reputationTier
        self.isSuspended = isSuspended
        self.createdAt = createdAt
        self.deletedAt = deletedAt
    }

    // Tolerant decoding: the profiles table has nullable columns and does not
    // store reputation_tier, so every non-key field needs a sensible default.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(UUID.self, forKey: .id)
        fullName       = try c.decodeIfPresent(String.self, forKey: .fullName) ?? "Member"
        username       = try c.decodeIfPresent(String.self, forKey: .username)
        avatarURL      = try c.decodeIfPresent(String.self, forKey: .avatarURL)
        bio            = try c.decodeIfPresent(String.self, forKey: .bio)
        city           = try c.decodeIfPresent(String.self, forKey: .city)
        phone          = try c.decodeIfPresent(String.self, forKey: .phone)
        points         = try c.decodeIfPresent(Int.self, forKey: .points) ?? 0
        role           = try c.decodeIfPresent(String.self, forKey: .role)
        reputationTier = try c.decodeIfPresent(ReputationTier.self, forKey: .reputationTier) ?? .bronze
        isSuspended    = try c.decodeIfPresent(Bool.self, forKey: .isSuspended) ?? false
        createdAt      = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        deletedAt      = try c.decodeIfPresent(Date.self, forKey: .deletedAt)
    }
}
