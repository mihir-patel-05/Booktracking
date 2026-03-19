import SwiftUI
import SwiftData

struct QuotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Quote.dateCreated, order: .reverse) private var quotes: [Quote]
    @State private var showAddQuote = false
    @State private var searchText = ""

    private var filteredQuotes: [Quote] {
        guard !searchText.isEmpty else { return quotes }
        return quotes.filter {
            $0.text.localizedCaseInsensitiveContains(searchText) ||
            ($0.book?.title.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if quotes.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredQuotes) { quote in
                                QuoteCard(quote: quote)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            modelContext.delete(quote)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Quotes")
            #if os(iOS)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
            .searchable(text: $searchText, prompt: "Search quotes...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddQuote = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showAddQuote) {
                AddQuoteView()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "quote.opening")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)

            Text("No Quotes Yet")
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)

            Text("Save memorable passages from your reading sessions.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

#Preview {
    QuotesView()
        .modelContainer(for: [Book.self, Quote.self])
        .preferredColorScheme(.dark)
}
