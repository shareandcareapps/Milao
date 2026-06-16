import Foundation
import Supabase

// Single shared client — mirrors the single-connection pattern from the RN app.
// Never instantiate a second SupabaseClient; it opens a duplicate realtime connection.
let supabase = SupabaseClient(
    supabaseURL: MilaoConfig.supabaseURL,
    supabaseKey: MilaoConfig.supabaseKey
)

enum MilaoConfig {
    static let supabaseURL = URL(string: "https://evdtdsvbaxneywahuxgw.supabase.co")!
    // Publishable (anon) key — safe to ship in the client binary
    static let supabaseKey = "sb_publishable_wwRWRTsAwMIg9FdAzvei-A_I-fXt-Rz"
}
