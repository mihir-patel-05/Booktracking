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
        HStack(spacing: 12) {
            coverImage(width: 50, height: 75)

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                Text(book.author)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)

                if book.status == .currentlyReading {
                    ProgressBar(progress: book.progressPercentage)
                        .padding(.top, 4)

                    Text("\(book.currentPage)/\(book.totalPages) pages")
                        .font(.caption2)
                        .foregroundStyle(Theme.textMuted)
                } else {
                    Text(book.status.rawValue)
                        .font(.caption2)
                        .foregroundStyle(Theme.textMuted)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            coverImage(width: 80, height: 120)

            Text(book.title)
                .font(.caption.bold())
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2)

            if book.status == .currentlyReading {
                ProgressBar(progress: book.progressPercentage, height: 4)
            }
        }
        .frame(width: 100)
        .padding(8)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func coverImage(width: CGFloat, height: CGFloat) -> some View {
        Group {
            if let urlString = book.coverURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        coverPlaceholder
                    }
                }
            } else {
                coverPlaceholder
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var coverPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Theme.cardBackgroundLight)
            .overlay(
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(Theme.textMuted)
            )
    }
}
