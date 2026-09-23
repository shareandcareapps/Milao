import Foundation

// MARK: - NewsArticle (matches `news` Supabase table)

struct NewsArticle: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    var title: String
    var summary: String?
    var body: String
    var category: String?
    var author: String?
    var isPinned: Bool
    var imageURL: String?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, summary, body, category, author
        case isPinned  = "is_pinned"
        case imageURL  = "image_url"
        case createdAt = "created_at"
    }

    // Custom decode: the live `news` table has no `is_pinned` column yet,
    // so default it to false instead of failing to decode the whole row.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        summary = try c.decodeIfPresent(String.self, forKey: .summary)
        body = try c.decode(String.self, forKey: .body)
        category = try c.decodeIfPresent(String.self, forKey: .category)
        author = try c.decodeIfPresent(String.self, forKey: .author)
        isPinned = try c.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        imageURL = try c.decodeIfPresent(String.self, forKey: .imageURL)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }

    init(id: UUID, title: String, summary: String?, body: String, category: String?, author: String?, isPinned: Bool, imageURL: String?, createdAt: Date) {
        self.id = id
        self.title = title
        self.summary = summary
        self.body = body
        self.category = category
        self.author = author
        self.isPinned = isPinned
        self.imageURL = imageURL
        self.createdAt = createdAt
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: createdAt)
    }
}

// MARK: - News categories

enum NewsCategory: String, CaseIterable, Identifiable {
    case community   = "Community"
    case safety      = "Safety"
    case market      = "Market"
    case immigration = "Immigration"
    case policy      = "Policy"
    case events      = "Events"

    var id: String { rawValue }
}
