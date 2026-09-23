import Foundation
import Supabase

@Observable
@MainActor
final class AdminService {
    var reports: [AdminReport] = []
    var newUsersLast7Days = 0
    var isLoading = false
    var error: String?

    // MARK: - Dashboard

    func fetchDashboard() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            reports = try await supabase
                .from("reports")
                .select("""
                    id, reporter_id, reported_user_id, listing_id, ride_id, reason, notes, status, created_at, \
                    reporter:profiles!reports_reporter_id_fkey(full_name), \
                    reported_user:profiles!reports_reported_user_id_fkey(full_name), \
                    listing:listings(title), \
                    ride:rides(from_location,to_location)
                    """)
                .eq("status", value: "pending")
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value

            let sevenDaysAgo = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-7 * 24 * 3600))
            let response = try await supabase
                .from("profiles")
                .select("*", head: true, count: .exact)
                .gte("created_at", value: sevenDaysAgo)
                .execute()
            newUsersLast7Days = response.count ?? 0
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Actions

    func updateReportStatus(id: UUID, status: String) async throws {
        try await supabase
            .from("reports")
            .update(["status": status])
            .eq("id", value: id.uuidString)
            .execute()
        reports.removeAll { $0.id == id }
    }

    func suspendUser(id: UUID) async throws {
        try await supabase
            .from("profiles")
            .update(["suspended": true])
            .eq("id", value: id.uuidString)
            .execute()
    }
}
