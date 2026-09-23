import Foundation

// MARK: - Admin Report (matches `reports` table, enriched with embedded context)

struct AdminReport: Codable, Identifiable, Sendable {
    let id: UUID
    var reporterId: UUID
    var reportedUserId: UUID?
    var listingId: UUID?
    var rideId: UUID?
    var reason: String
    var notes: String?
    var status: String            // pending | reviewed | resolved | dismissed
    var createdAt: Date

    var reporter: NameRef?
    var reportedUser: NameRef?
    var listing: TitleRef?
    var ride: RouteRef?

    struct NameRef: Codable, Sendable {
        var fullName: String
        enum CodingKeys: String, CodingKey { case fullName = "full_name" }
    }

    struct TitleRef: Codable, Sendable {
        var title: String
    }

    struct RouteRef: Codable, Sendable {
        var fromLocation: String
        var toLocation: String
        enum CodingKeys: String, CodingKey {
            case fromLocation = "from_location"
            case toLocation   = "to_location"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, reason, notes, status
        case reporterId     = "reporter_id"
        case reportedUserId = "reported_user_id"
        case listingId      = "listing_id"
        case rideId         = "ride_id"
        case createdAt      = "created_at"
        case reporter
        case reportedUser   = "reported_user"
        case listing, ride
    }

    /// Short human summary of what's being reported, for the queue row.
    var targetSummary: String {
        if let listing { return "Listing: \(listing.title)" }
        if let ride { return "Ride: \(ride.fromLocation) → \(ride.toLocation)" }
        if let reportedUser { return "User: \(reportedUser.fullName)" }
        return "General report"
    }
}
