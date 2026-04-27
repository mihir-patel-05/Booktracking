import SwiftUI
import SwiftData

struct QuotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Quote.dateCreated, order: .reverse) private var quotes: [Quote]
    @State private var showAddQuote = false
    @State private var searchText = ""
    @State private var featuredIndex = 0

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
                        VStack(alignment: .leading, spacing: 0) {
                            header
                                .padding(.horizontal, 20)
                                .padding(.top, 16)

                            searchBar
                                .padding(.horizontal, 20)
                                .padding(.top, 12)

                            if searchText.isEmpty, !quotes.isEmpty {
                                featuredCard
                                    .padding(.horizontal, 20)
                                    .padding(.top, 16)
                            }

                            countLabel
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                                .padding(.bottom, 12)

                            VStack(spacing: 10) {
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
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            #if os(iOS)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddQuote = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.accentLight)
                    }
                }
            }
            .sheet(isPresented: $showAddQuote) {
                AddQuoteView()
            }
        }
    }

    private var header: some View {
        Text("Quotes")
            .font(.playfair(26, weight: .bold))
            .foregroundStyle(Theme.textPrimary)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textMuted)
            TextField("Search quotes...", text: $searchText)
                .font(.dmSans(14))
                .foregroundStyle(Theme.textPrimary)
                .tint(Theme.accentLight)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .designCard(cornerRadius: 12)
    }

    private var featuredCard: some View {
        let quote = quotes[min(featuredIndex, quotes.count - 1)]

        return ZStack(alignment: .topLeading) {
            // Decorative giant quote glyph
            Text("\u{201C}")
                .font(.custom("Playfair Display", size: 160))
                .foregroundStyle(Color(hex: "7C3AED").opacity(0.07))
                .offset(x: -8, y: -50)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 18) {
                Text(quote.text)
                    .font(.playfair(17, weight: .semibold))
                    .italic()
                    .foregroundStyle(Theme.textPrimary)
                    .lineSpacing(6)
                    .multilineTextAlignment(.leading)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if let book = quote.book {
                            Text("— \(book.title)")
                                .font(.dmSans(12, weight: .semibold))
                                .foregroundStyle(Theme.accentLight)
                        }
                        Text(quote.dateCreated.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.dmSans(10))
                            .foregroundStyle(Theme.textMuted)
                    }
                    Spacer()
                    Button {
                        featuredIndex = Int.random(in: 0..<quotes.count)
                    } label: {
                        HStack(spacing: 6) {
                            Text("Random")
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                        }
                        .font(.dmSans(12, weight: .semibold))
                        .foregroundStyle(Theme.accentLight)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.accent.opacity(0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Theme.accent.opacity(0.4), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        .bannerCard(cornerRadius: 20)
    }

    private var countLabel: some View {
        Text("\(filteredQuotes.count) saved quote\(filteredQuotes.count == 1 ? "" : "s")")
            .font(.dmSans(11))
            .foregroundStyle(Theme.textMuted)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Text("\u{201C}\u{201D}").font(.playfair(52, weight: .bold))
                .foregroundStyle(Theme.accent)
            Text("No Quotes Yet")
                .font(.playfair(22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Save memorable passages from your reading sessions.")
                .font(.dmSans(14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button { showAddQuote = true } label: {
                Text("Add a quote")
            }
            .buttonStyle(PrimaryGradientButtonStyle())
            .frame(maxWidth: 220)
            .padding(.top, 6)
        }
    }
}

#Preview {
    QuotesView()
        .modelContainer(for: [Book.self, Quote.self])
        .preferredColorScheme(.dark)
}
