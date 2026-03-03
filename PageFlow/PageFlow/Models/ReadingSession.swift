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
    }
}
