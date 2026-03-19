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

        do {
            try await syncSessions(modelContext: modelContext, userId: userId)
        } catch {
            print("Session sync failed: \(error)")
        }

        do {
            try await syncNotes(modelContext: modelContext, userId: userId)
        } catch {
            print("Notes sync failed: \(error)")
        }

        do {
            try await syncQuotes(modelContext: modelContext, userId: userId)
        } catch {
            print("Quotes sync failed: \(error)")
        }

        do {
            try await syncStats(modelContext: modelContext, userId: userId)
        } catch {
            print("Stats sync failed: \(error)")
        }
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

    private func syncSessions(modelContext: ModelContext, userId: String) async throws {
        let descriptor = FetchDescriptor<ReadingSession>(
            predicate: #Predicate<ReadingSession> { $0.needsSync == true }
        )
        let unsynced = try modelContext.fetch(descriptor)

        for session in unsynced {
            let dto = ReadingSessionDTO(
                id: session.id.uuidString,
                user_id: userId,
                book_id: session.book?.id.uuidString ?? "",
                start_date: session.startDate,
                duration_seconds: session.durationSeconds,
                mood_tags: session.moodTags,
                reflection_prompt: session.reflectionPrompt,
                reflection_text: session.reflectionText,
                xp_earned: session.xpEarned
            )

            try await supabase
                .from("reading_sessions")
                .upsert(dto)
                .execute()

            session.needsSync = false
        }
    }

    private func syncNotes(modelContext: ModelContext, userId: String) async throws {
        let descriptor = FetchDescriptor<SessionNote>(
            predicate: #Predicate<SessionNote> { $0.needsSync == true }
        )
        let unsynced = try modelContext.fetch(descriptor)

        for note in unsynced {
            let dto = SessionNoteDTO(
                id: note.id.uuidString,
                user_id: userId,
                book_id: note.book?.id.uuidString ?? "",
                session_id: note.session?.id.uuidString,
                title: note.title,
                content: note.content,
                tags: note.tags,
                chapter_reference: note.chapterReference,
                date_created: note.dateCreated
            )

            try await supabase
                .from("session_notes")
                .upsert(dto)
                .execute()

            note.needsSync = false
        }
    }

    private func syncQuotes(modelContext: ModelContext, userId: String) async throws {
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate<Quote> { $0.needsSync == true }
        )
        let unsynced = try modelContext.fetch(descriptor)

        for quote in unsynced {
            let dto = QuoteDTO(
                id: quote.id.uuidString,
                user_id: userId,
                book_id: quote.book?.id.uuidString ?? "",
                session_id: quote.session?.id.uuidString,
                text: quote.text,
                date_created: quote.dateCreated
            )

            try await supabase
                .from("quotes")
                .upsert(dto)
                .execute()

            quote.needsSync = false
        }
    }

    private func syncStats(modelContext: ModelContext, userId: String) async throws {
        let descriptor = FetchDescriptor<UserStats>(
            predicate: #Predicate<UserStats> { $0.needsSync == true }
        )
        let unsynced = try modelContext.fetch(descriptor)

        for stats in unsynced {
            let dto = UserStatsDTO(
                id: stats.id.uuidString,
                user_id: userId,
                total_xp: stats.totalXP,
                current_streak: stats.currentStreak,
                longest_streak: stats.longestStreak,
                last_session_date: stats.lastSessionDate,
                streak_freezes_used_this_month: stats.streakFreezesUsedThisMonth,
                streak_freeze_month_marker: stats.streakFreezeMonthMarker
            )

            try await supabase
                .from("user_stats")
                .upsert(dto)
                .execute()

            stats.needsSync = false
        }
    }
}
