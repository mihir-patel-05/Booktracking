import SwiftUI

struct BookCard: View {
    let book: Book
    var compact: Bool = false

    var body: some View {
        if compact {
            compactLayout
        } else {
            fullLayout
        }
    }

    private var fullLayout: some View {
        HStack(spacing: 14) {
            BookCoverView(book: book, size: .sm)

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.dmSans(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                Text(book.author)
                    .font(.dmSans(11))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)

                if book.status == .currentlyReading {
                    ProgressBarV2(value: book.progressPercentage, height: 4)
                        .padding(.top, 4)

                    Text("\(book.currentPage)/\(book.totalPages) pages")
                        .font(.dmSans(10))
                        .foregroundStyle(Theme.textMuted)
                } else {
                    Text(book.status.rawValue)
                        .font(.dmSans(10))
                        .foregroundStyle(Theme.textMuted)
                }
            }

            Spacer()
        }
        .padding(14)
        .designCard(cornerRadius: 14)
    }

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: 11) {
            BookCoverView(book: book, size: .md)

            VStack(alignment: .leading, spacing: 3) {
                Text(book.title)
                    .font(.dmSans(13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)

                Text(book.author)
                    .font(.dmSans(11))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }

            if book.status == .currentlyReading {
                ProgressBarV2(value: book.progressPercentage, height: 4)
                HStack {
                    Text("\(Int(book.progressPercentage * 100))%")
                        .font(.dmSans(11, weight: .semibold))
                        .foregroundStyle(Theme.accentLight)
                    Spacer()
                    Text("\(book.notes.count) notes")
                        .font(.dmSans(11))
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
        .frame(width: 155, alignment: .leading)
        .padding(14)
        .designCard(cornerRadius: 18)
    }
}
