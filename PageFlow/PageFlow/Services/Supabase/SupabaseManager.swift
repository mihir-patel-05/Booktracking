import Foundation
import Supabase

@Observable
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    // TODO: Move these to a Config.plist or environment variables before shipping
    private static let supabaseURL = "YOUR_SUPABASE_URL"
    private static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Self.supabaseURL)!,
            supabaseKey: Self.supabaseAnonKey
        )
    }
}
