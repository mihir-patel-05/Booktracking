import SwiftUI

struct QuoteCard: View {
    let quote: Quote

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let book = quote.book {
                BookCoverView(book: book, size: .sm)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("\u{201C}\(quote.text)\u{201D}")
                    .font(.playfair(14, weight: .regular))
                    .italic()
                    .foregroundStyle(Theme.textPrimary)
                    .lineSpacing(4)

                HStack {
                    if let book = quote.book {
                        Text(book.title)
                            .font(.dmSans(11, weight: .semibold))
                            .foregroundStyle(Theme.accentLight)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text(quote.dateCreated.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.dmSans(10))
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
        .padding(16)
        .designCard(cornerRadius: 16)
    }
}
