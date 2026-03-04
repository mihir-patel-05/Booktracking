import Foundation
import SwiftData
import Supabase

/// Scaffold for background sync between SwiftData and Supabase.
/// Full sync logic will be built incrementally in later phases.
@Observable
final class SyncService {
    private let supabase = SupabaseManager.shared.client

    var isSyncing = false
    var lastSyncDate: Date?

    // MARK: - Supabase DTOs

    struct BookDTO: Codable {
        let id: String
        let user_id: String
        let title: String
        let author: String
        let cover_url: String?
        let total_pages: Int
        let current_page: Int
        let status: String
        let date_added: Date
        let date_completed: Date?
    }

    struct ReadingSessionDTO: Codable {
        let id: String
        let user_id: String
        let book_id: String
        let start_date: Date
        let duration_seconds: Int
        let mood_tags: [String]
        let reflection_prompt: String?
        let reflection_text: String?
        let xp_earned: Int
    }

    struct SessionNoteDTO: Codable {
        let id: String
        let user_id: String
        let book_id: String
        let session_id: String?
        let title: String
        let content: String
        let tags: [String]
        let chapter_reference: String?
        let date_created: Date
    }

    struct QuoteDTO: Codable {
        let id: String
        let user_id: String
        let book_id: String
        let session_id: String?
        let text: String
        let date_created: Date
    }

    struct UserStatsDTO: Codable {
        let id: String
        let user_id: String
        let total_xp: Int
        let current_streak: Int
        let longest_streak: Int
        let last_session_date: Date?
        let streak_freezes_used_this_month: Int
        let streak_freeze_month_marker: Int
    }

    // MARK: - Sync (placeholder — will be implemented in later phases)

    func syncAll(modelContext: ModelContext, userId: String) async {
        guard !isSyncing else { return }
        isSyncing = true
        defer {
            isSyncing = false
            lastSyncDate = Date()
        }

        // TODO: Phase 2+ — implement per-entity sync:
        // 1. Query SwiftData for items where needsSync == true
        // 2. Upsert to Supabase
        // 3. Mark needsSync = false on success
        // 4. Pull remote changes not in local store
    }
}
