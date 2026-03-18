import SwiftUI

struct QuoteCard: View {
    let quote: Quote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "quote.opening")
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
                Spacer()
            }

            Text(quote.text)
                .font(.body)
                .foregroundStyle(Theme.textPrimary)
                .italic()

            HStack {
                if let book = quote.book {
                    Text(book.title)
                        .font(.caption.bold())
                        .foregroundStyle(Theme.accentLight)
                }
                Spacer()
                Text(quote.dateCreated.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
