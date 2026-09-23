import Foundation
import Supabase

@Observable
@MainActor
final class ListingsService {
    var listings: [Listing] = []
    var isLoading = false
    var error: String?

    // MARK: - Fetch

    func fetchAll(category: String? = nil) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            if let cat = category, cat != "all" {
                listings = try await supabase
                    .from("listings")
                    .select()
                    .eq("status", value: "active")
                    .eq("category", value: cat)
                    .order("is_boosted", ascending: false)
                    .order("created_at", ascending: false)
                    .limit(40)
                    .execute()
                    .value
            } else {
                listings = try await supabase
                    .from("listings")
                    .select()
                    .eq("status", value: "active")
                    .order("is_boosted", ascending: false)
                    .order("created_at", ascending: false)
                    .limit(40)
                    .execute()
                    .value
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func fetchHome() async -> [Listing] {
        do {
            return try await supabase
                .from("listings")
                .select()
                .eq("status", value: "active")
                .not("category", operator: .eq, value: "events")
                .order("is_boosted", ascending: false)
                .order("created_at", ascending: false)
                .limit(6)
                .execute()
                .value
        } catch { return [] }
    }

    func fetchEvents() async -> [Listing] {
        do {
            return try await supabase
                .from("listings")
                .select()
                .eq("status", value: "active")
                .eq("category", value: "events")
                .order("created_at", ascending: false)
                .limit(6)
                .execute()
                .value
        } catch { return [] }
    }

    func fetchMine(userId: UUID) async -> [Listing] {
        error = nil
        do {
            return try await supabase
                .from("listings")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {
            self.error = error.localizedDescription
            return []
        }
    }

    // MARK: - Post

    func post(
        userId: UUID,
        title: String,
        description: String,
        category: String,
        price: Double?,
        images: [String],
        metadata: [String: AnyJSON]
    ) async throws -> Listing {
        var body: [String: AnyJSON] = [
            "user_id":    .string(userId.uuidString),
            "title":      .string(title),
            "description": .string(description),
            "category":   .string(category),
            "status":     .string("active"),
            "images":     .array(images.map { .string($0) }),
            "is_boosted": .bool(false),
        ]
        if let price { body["price"] = .double(price) }
        // `metadata` is a `text` column holding a JSON string, not `jsonb` — encode it as such.
        if !metadata.isEmpty,
           let data = try? JSONEncoder().encode(AnyJSON.object(metadata)),
           let jsonString = String(data: data, encoding: .utf8) {
            body["metadata"] = .string(jsonString)
        }

        return try await supabase
            .from("listings")
            .insert(body)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Edit

    func update(id: UUID, updates: [String: AnyJSON]) async throws {
        try await supabase
            .from("listings")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()
        if let idx = listings.firstIndex(where: { $0.id == id }) {
            listings[idx] = try await fetchById(id: id)
        }
    }

    func markSold(id: UUID) async throws {
        try await supabase
            .from("listings")
            .update(["status": "sold"])
            .eq("id", value: id.uuidString)
            .execute()
        listings.removeAll { $0.id == id }
    }

    func delete(id: UUID) async throws {
        try await supabase
            .from("listings")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
        listings.removeAll { $0.id == id }
    }

    // MARK: - Helpers

    func fetchById(id: UUID) async throws -> Listing {
        try await supabase
            .from("listings")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    func uploadImage(_ data: Data, ext: String = "jpg") async throws -> String {
        let path = "listings/\(UUID().uuidString).\(ext)"
        try await supabase.storage
            .from("listings")
            .upload(path, data: data, options: .init(contentType: "image/\(ext)"))
        return try supabase.storage
            .from("listings")
            .getPublicURL(path: path)
            .absoluteString
    }
}
