import Foundation
import Supabase

// MARK: - Blocked User (matches `blocked_users` table, enriched with the blocked profile's name)

struct BlockedUser: Codable, Identifiable, Sendable {
    let id: UUID
    var blockedId: UUID
    var createdAt: Date
    var blocked: NameRef?

    struct NameRef: Codable, Sendable {
        var fullName: String
        enum CodingKeys: String, CodingKey { case fullName = "full_name" }
    }

    enum CodingKeys: String, CodingKey {
        case id, blocked
        case blockedId = "blocked_id"
        case createdAt = "created_at"
    }
}

@Observable
@MainActor
final class BlockedUsersService {
    var blockedUsers: [BlockedUser] = []
    var isLoading = false
    var error: String?

    func fetchBlockedUsers() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            blockedUsers = try await supabase
                .from("blocked_users")
                .select("id, blocked_id, created_at, blocked:profiles!blocked_users_blocked_id_fkey(full_name)")
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {
            self.error = error.localizedDescription
        }
    }

    func isBlocked(blockerId: UUID, blockedId: UUID) async -> Bool {
        let rows: [[String: AnyJSON]] = (try? await supabase
            .from("blocked_users")
            .select("id")
            .eq("blocker_id", value: blockerId.uuidString)
            .eq("blocked_id", value: blockedId.uuidString)
            .execute()
            .value) ?? []
        return !rows.isEmpty
    }

    func block(blockerId: UUID, blockedId: UUID) async throws {
        let payload: [String: AnyJSON] = [
            "blocker_id": .string(blockerId.uuidString),
            "blocked_id": .string(blockedId.uuidString),
        ]
        do {
            try await supabase.from("blocked_users").insert(payload).execute()
        } catch let error as PostgrestError where error.code == "23505" {
            // Already blocked — ignore duplicate.
        }
    }

    func unblock(blockerId: UUID, blockedId: UUID) async throws {
        try await supabase
            .from("blocked_users")
            .delete()
            .eq("blocker_id", value: blockerId.uuidString)
            .eq("blocked_id", value: blockedId.uuidString)
            .execute()
        blockedUsers.removeAll { $0.blockedId == blockedId }
    }
}
