import Foundation
import SwiftData

@Model
final class ReadingSession {
    var id: UUID
    var book: Book?
    var startDate: Date
    var durationSeconds: Int
    var moodTags: [String]
    var reflectionPrompt: String?
    var reflectionText: String?
    var xpEarned: Int
    var needsSync: Bool
    var supabaseUserId: String?

    @Relationship(deleteRule: .nullify, inverse: \SessionNote.session)
    var notes: [SessionNote] = []

    @Relationship(deleteRule: .nullify, inverse: \Quote.session)
    var quotes: [Quote] = []

    init(
        book: Book,
        startDate: Date = Date(),
        durationSeconds: Int,
        moodTags: [String] = [],
        reflectionPrompt: String? = nil,
        reflectionText: String? = nil,
        xpEarned: Int = 0
    ) {
        self.id = UUID()
        self.book = book
        self.startDate = startDate
        self.durationSeconds = durationSeconds
        self.moodTags = moodTags
        self.reflectionPrompt = reflectionPrompt
        self.reflectionText = reflectionText
        self.xpEarned = xpEarned
        self.needsSync = true
    }
}
