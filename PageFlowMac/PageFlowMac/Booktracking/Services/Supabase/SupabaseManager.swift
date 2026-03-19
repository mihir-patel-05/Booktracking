import Foundation
import Supabase

@Observable
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        guard
            let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path),
            let urlString = dict["SUPABASE_URL"] as? String,
            let anonKey = dict["SUPABASE_ANON_KEY"] as? String,
            let url = URL(string: urlString)
        else {
            fatalError("Missing or invalid Secrets.plist. Copy Secrets.example.plist to PageFlow/Secrets.plist and add your Supabase credentials.")
        }

        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey
        )
    }
}
