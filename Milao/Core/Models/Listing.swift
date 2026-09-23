import Foundation

// MARK: - Listing (matches `listings` Supabase table)

struct Listing: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    var userId: UUID
    var title: String
    var description: String
    var category: String          // housing | buysell | food | jobs | events | accommodation
    var price: Double?
    var status: String            // active | sold | archived
    var images: [String]
    var metadata: ListingMetadata?
    var isBoosted: Bool
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, description, category, price, status, images, metadata
        case userId     = "user_id"
        case isBoosted  = "is_boosted"
        case createdAt  = "created_at"
    }

    // The live `metadata` column is `text`, not `jsonb` — it holds a JSON string,
    // not a nested object — so it needs a manual bridge on both sides.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        userId = try c.decode(UUID.self, forKey: .userId)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        category = try c.decode(String.self, forKey: .category)
        price = try c.decodeIfPresent(Double.self, forKey: .price)
        status = try c.decode(String.self, forKey: .status)
        images = try c.decodeIfPresent([String].self, forKey: .images) ?? []
        if let raw = try c.decodeIfPresent(String.self, forKey: .metadata),
           let data = raw.data(using: .utf8) {
            metadata = try? JSONDecoder().decode(ListingMetadata.self, from: data)
        } else {
            metadata = nil
        }
        isBoosted = try c.decode(Bool.self, forKey: .isBoosted)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encode(title, forKey: .title)
        try c.encode(description, forKey: .description)
        try c.encode(category, forKey: .category)
        try c.encodeIfPresent(price, forKey: .price)
        try c.encode(status, forKey: .status)
        try c.encode(images, forKey: .images)
        if let metadata,
           let data = try? JSONEncoder().encode(metadata),
           let str = String(data: data, encoding: .utf8) {
            try c.encode(str, forKey: .metadata)
        } else {
            try c.encodeNil(forKey: .metadata)
        }
        try c.encode(isBoosted, forKey: .isBoosted)
        try c.encode(createdAt, forKey: .createdAt)
    }

    init(id: UUID, userId: UUID, title: String, description: String, category: String, price: Double?, status: String, images: [String], metadata: ListingMetadata?, isBoosted: Bool, createdAt: Date) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.category = category
        self.price = price
        self.status = status
        self.images = images
        self.metadata = metadata
        self.isBoosted = isBoosted
        self.createdAt = createdAt
    }

    // Convenience helpers
    var categoryEnum: ListingCategoryKind { ListingCategoryKind(rawValue: category) ?? .buySell }
    var firstImage: String? { images.first }
    var formattedPrice: String? { price.map { "$\(Int($0))" } }
    var isFood: Bool { category == "food" }
}

// MARK: - Listing Metadata (jsonb — sparse, varies by category)

struct ListingMetadata: Codable, Sendable, Hashable {
    var location: String?
    var businessName: String?
    var allergens: String?
    var attested: Bool?
    var attestedAt: String?
    var bedrooms: Int?
    var bathrooms: Int?
    var company: String?
    var salaryRange: String?
    var condition: String?
    var brand: String?
    var eventDate: String?
    var venue: String?
    var ticketLink: String?

    enum CodingKeys: String, CodingKey {
        case location
        case businessName  = "business_name"
        case allergens
        case attested
        case attestedAt    = "attested_at"
        case bedrooms, bathrooms
        case company
        case salaryRange   = "salary_range"
        case condition, brand
        case eventDate     = "event_date"
        case venue
        case ticketLink    = "ticket_link"
    }
}

// MARK: - Category kind (UI helper, not persisted as enum)

enum ListingCategoryKind: String, CaseIterable, Identifiable {
    case all           = "all"
    case housing       = "housing"
    case accommodation = "accommodation"
    case jobs          = "jobs"
    case buySell       = "buysell"
    case food          = "food"
    case events        = "events"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:           "All"
        case .housing:       "Housing"
        case .accommodation: "Stays"
        case .jobs:          "Jobs"
        case .buySell:       "Buy & Sell"
        case .food:          "Food"
        case .events:        "Events"
        }
    }

    var icon: String {
        switch self {
        case .all:           "square.grid.2x2.fill"
        case .housing:       "building.2.fill"
        case .accommodation: "bed.double.fill"
        case .jobs:          "briefcase.fill"
        case .buySell:       "bag.fill"
        case .food:          "fork.knife"
        case .events:        "calendar"
        }
    }

    // Per-tab accent colours
    var gradientColors: [String] {
        switch self {
        case .all:           ["E8185C", "FF5580"]
        case .housing:       ["FF6B6B", "E84393"]
        case .accommodation: ["F0883E", "D4691E"]
        case .jobs:          ["00C48C", "007A5E"]
        case .buySell:       ["0099FF", "0055CC"]
        case .food:          ["E8185C", "E68A00"]
        case .events:        ["9B59B6", "6C3483"]
        }
    }
}
