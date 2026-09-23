import Foundation
import Supabase

@Observable
@MainActor
final class NewsService {
    var articles: [NewsArticle] = []
    var isLoading = false
    var error: String?

    func fetchAll(category: String? = nil) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            if let cat = category {
                articles = try await supabase
                    .from("news")
                    .select()
                    .eq("category", value: cat)
                    .order("is_pinned", ascending: false)
                    .order("created_at", ascending: false)
                    .limit(30)
                    .execute()
                    .value
            } else {
                articles = try await supabase
                    .from("news")
                    .select()
                    .order("is_pinned", ascending: false)
                    .order("created_at", ascending: false)
                    .limit(30)
                    .execute()
                    .value
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func fetchHome() async -> [NewsArticle] {
        do {
            return try await supabase
                .from("news")
                .select()
                .order("created_at", ascending: false)
                .limit(5)
                .execute()
                .value
        } catch { return [] }
    }

    func create(title: String, summary: String, body: String, category: String, author: String, isPinned: Bool, userId: UUID) async throws -> NewsArticle {
        // Verify admin (RLS enforces on server; we just pass along)
        let payload: [String: AnyJSON] = [
            "title":     .string(title),
            "summary":   .string(summary),
            "body":      .string(body),
            "category":  .string(category),
            "author":    .string(author),
            "is_pinned": .bool(isPinned),
        ]
        return try await supabase
            .from("news")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    func update(id: UUID, updates: [String: AnyJSON]) async throws {
        try await supabase
            .from("news")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()
        if let idx = articles.firstIndex(where: { $0.id == id }) {
            articles[idx] = try await fetchById(id: id)
        }
    }

    func delete(id: UUID) async throws {
        try await supabase
            .from("news")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
        articles.removeAll { $0.id == id }
    }

    private func fetchById(id: UUID) async throws -> NewsArticle {
        try await supabase
            .from("news")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }
}
