import Foundation
import SwiftData

@Model
final class Book {
    var id: UUID
    var title: String
    var author: String
    var coverURL: String?
    var totalPages: Int
    var currentPage: Int
    var statusRawValue: String
    var dateAdded: Date
    var dateCompleted: Date?

    @Relationship(deleteRule: .cascade, inverse: \ReadingSession.book)
    var sessions: [ReadingSession] = []

    @Relationship(deleteRule: .cascade, inverse: \SessionNote.book)
    var notes: [SessionNote] = []

    @Relationship(deleteRule: .cascade, inverse: \Quote.book)
    var quotes: [Quote] = []

    var status: BookStatus {
        get { BookStatus(rawValue: statusRawValue) ?? .wantToRead }
        set { statusRawValue = newValue.rawValue }
    }

    var progressPercentage: Double {
        guard totalPages > 0 else { return 0 }
        return min(Double(currentPage) / Double(totalPages), 1.0)
    }

    init(
        title: String,
        author: String,
        coverURL: String? = nil,
        totalPages: Int,
        currentPage: Int = 0,
        status: BookStatus = .wantToRead
    ) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.statusRawValue = status.rawValue
        self.dateAdded = Date()
    }
}
