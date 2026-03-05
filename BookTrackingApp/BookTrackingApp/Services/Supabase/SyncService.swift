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

    // MARK: - Sync

    func syncAll(modelContext: ModelContext, userId: String) async {
        guard !isSyncing else { return }
        isSyncing = true
        defer {
            isSyncing = false
            lastSyncDate = Date()
        }

        do {
            try await syncBooks(modelContext: modelContext, userId: userId)
        } catch {
            print("Book sync failed: \(error)")
        }

        // TODO: Future phases — syncSessions, syncNotes, syncQuotes, syncStats
    }

    private func syncBooks(modelContext: ModelContext, userId: String) async throws {
        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate<Book> { $0.needsSync == true }
        )
        let unsyncedBooks = try modelContext.fetch(descriptor)

        for book in unsyncedBooks {
            let dto = BookDTO(
                id: book.id.uuidString,
                user_id: userId,
                title: book.title,
                author: book.author,
                cover_url: book.coverURL,
                total_pages: book.totalPages,
                current_page: book.currentPage,
                status: book.statusRawValue,
                date_added: book.dateAdded,
                date_completed: book.dateCompleted
            )

            try await supabase
                .from("books")
                .upsert(dto)
                .execute()

            book.needsSync = false
        }
    }
}
