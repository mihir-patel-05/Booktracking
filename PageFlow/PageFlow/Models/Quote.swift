import Foundation
import SwiftData

@Model
final class Quote {
    var id: UUID
    var book: Book?
    var session: ReadingSession?
    var text: String
    var dateCreated: Date

    init(
        book: Book,
        session: ReadingSession? = nil,
        text: String
    ) {
        self.id = UUID()
        self.book = book
        self.session = session
        self.text = text
        self.dateCreated = Date()
    }
}
