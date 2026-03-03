import Foundation
import SwiftData

@Model
final class SessionNote {
    var id: UUID
    var book: Book?
    var session: ReadingSession?
    var title: String
    var content: String
    var tags: [String]
    var chapterReference: String?
    var dateCreated: Date
    var needsSync: Bool
    var supabaseUserId: String?

    init(
        book: Book,
        session: ReadingSession? = nil,
        title: String,
        content: String,
        tags: [String] = [],
        chapterReference: String? = nil
    ) {
        self.id = UUID()
        self.book = book
        self.session = session
        self.title = title
        self.content = content
        self.tags = tags
        self.chapterReference = chapterReference
        self.dateCreated = Date()
        self.needsSync = true
    }
}
