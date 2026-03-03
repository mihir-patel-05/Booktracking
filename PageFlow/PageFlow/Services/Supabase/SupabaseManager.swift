import Foundation
import Supabase

@Observable
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    // TODO: Replace with your actual Supabase credentials before running
    private static let supabaseURL = "YOUR_SUPABASE_URL"
    private static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"

    private init() {
        guard let url = URL(string: Self.supabaseURL) else {
            fatalError("Invalid Supabase URL. Update SupabaseManager with your project URL.")
        }
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: Self.supabaseAnonKey
        )
    }
}
