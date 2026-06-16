import Foundation

struct UserProfile: Codable, Identifiable, Sendable {
    let id: UUID
    var fullName: String
    var username: String?
    var avatarURL: String?
    var bio: String?
    var city: String?
    var points: Int
    var reputationTier: ReputationTier
    var isSuspended: Bool
    var createdAt: Date

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
        case id
        case fullName       = "full_name"
        case username
        case avatarURL      = "avatar_url"
        case bio
        case city
        case points
        case reputationTier = "reputation_tier"
        case isSuspended    = "is_suspended"
        case createdAt      = "created_at"
    }
}
