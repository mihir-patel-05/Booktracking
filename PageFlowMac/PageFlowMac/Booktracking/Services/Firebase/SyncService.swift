import Foundation
import SwiftData
import FirebaseFirestore

/// Background sync between SwiftData and Cloud Firestore.
@Observable
final class SyncService {
    private let firebase = FirebaseManager.shared

    var isSyncing = false
    var lastSyncDate: Date?

    // MARK: - Sync

    func syncAll(modelContext: ModelContext, userId: String) async {
        guard !isSyncing else { return }
        guard firebase.configureIfPossible() else {
            print(FirebaseConfigurationError.missingGoogleServiceInfo.localizedDescription)
            return
        }

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
            var data = baseDocument(id: book.id.uuidString, userId: userId)
            data["title"] = book.title
            data["author"] = book.author
            data["totalPages"] = book.totalPages
            data["currentPage"] = book.currentPage
            data["status"] = book.statusRawValue
            data["dateAdded"] = book.dateAdded
            setOptional(book.coverURL, for: "coverURL", in: &data)
            setOptional(book.dateCompleted, for: "dateCompleted", in: &data)

            try await userCollection("books", userId: userId)
                .document(book.id.uuidString)
                .setData(data, merge: true)

            book.needsSync = false
            book.supabaseUserId = userId
        }

        try modelContext.save()
    }

    private func syncSessions(modelContext: ModelContext, userId: String) async throws {
        let descriptor = FetchDescriptor<ReadingSession>(
            predicate: #Predicate<ReadingSession> { $0.needsSync == true }
        )
        let unsynced = try modelContext.fetch(descriptor)

        for session in unsynced {
            var data = baseDocument(id: session.id.uuidString, userId: userId)
            data["bookId"] = session.book?.id.uuidString ?? ""
            data["startDate"] = session.startDate
            data["durationSeconds"] = session.durationSeconds
            data["moodTags"] = session.moodTags
            data["xpEarned"] = session.xpEarned
            setOptional(session.reflectionPrompt, for: "reflectionPrompt", in: &data)
            setOptional(session.reflectionText, for: "reflectionText", in: &data)

            try await userCollection("readingSessions", userId: userId)
                .document(session.id.uuidString)
                .setData(data, merge: true)

            session.needsSync = false
            session.supabaseUserId = userId
        }

        try modelContext.save()
    }

    private func syncNotes(modelContext: ModelContext, userId: String) async throws {
        let descriptor = FetchDescriptor<SessionNote>(
            predicate: #Predicate<SessionNote> { $0.needsSync == true }
        )
        let unsynced = try modelContext.fetch(descriptor)

        for note in unsynced {
            var data = baseDocument(id: note.id.uuidString, userId: userId)
            data["bookId"] = note.book?.id.uuidString ?? ""
            data["title"] = note.title
            data["content"] = note.content
            data["tags"] = note.tags
            data["dateCreated"] = note.dateCreated
            setOptional(note.session?.id.uuidString, for: "sessionId", in: &data)
            setOptional(note.chapterReference, for: "chapterReference", in: &data)

            try await userCollection("sessionNotes", userId: userId)
                .document(note.id.uuidString)
                .setData(data, merge: true)

            note.needsSync = false
            note.supabaseUserId = userId
        }

        try modelContext.save()
    }

    private func syncQuotes(modelContext: ModelContext, userId: String) async throws {
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate<Quote> { $0.needsSync == true }
        )
        let unsynced = try modelContext.fetch(descriptor)

        for quote in unsynced {
            var data = baseDocument(id: quote.id.uuidString, userId: userId)
            data["bookId"] = quote.book?.id.uuidString ?? ""
            data["text"] = quote.text
            data["dateCreated"] = quote.dateCreated
            setOptional(quote.session?.id.uuidString, for: "sessionId", in: &data)

            try await userCollection("quotes", userId: userId)
                .document(quote.id.uuidString)
                .setData(data, merge: true)

            quote.needsSync = false
            quote.supabaseUserId = userId
        }

        try modelContext.save()
    }

    private func syncStats(modelContext: ModelContext, userId: String) async throws {
        let descriptor = FetchDescriptor<UserStats>(
            predicate: #Predicate<UserStats> { $0.needsSync == true }
        )
        let unsynced = try modelContext.fetch(descriptor)

        for stats in unsynced {
            var data = baseDocument(id: stats.id.uuidString, userId: userId)
            data["totalXP"] = stats.totalXP
            data["currentStreak"] = stats.currentStreak
            data["longestStreak"] = stats.longestStreak
            data["streakFreezesUsedThisMonth"] = stats.streakFreezesUsedThisMonth
            data["streakFreezeMonthMarker"] = stats.streakFreezeMonthMarker
            setOptional(stats.lastSessionDate, for: "lastSessionDate", in: &data)

            try await userCollection("userStats", userId: userId)
                .document(stats.id.uuidString)
                .setData(data, merge: true)

            stats.needsSync = false
            stats.supabaseUserId = userId
        }

        try modelContext.save()
    }

    // MARK: - Firestore Helpers

    private func userCollection(_ collection: String, userId: String) -> CollectionReference {
        Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection(collection)
    }

    private func baseDocument(id: String, userId: String) -> [String: Any] {
        [
            "id": id,
            "userId": userId,
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }

    private func setOptional(_ value: Any?, for key: String, in data: inout [String: Any]) {
        if let value {
            data[key] = value
        } else {
            data[key] = FieldValue.delete()
        }
    }
}
