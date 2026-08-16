import SwiftUI
import SwiftData

struct QuotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Quote.dateCreated, order: .reverse) private var quotes: [Quote]
    @State private var showAddQuote = false
    @State private var searchText = ""
    @State private var editingQuote: Quote?
    @State private var quotePendingDeletion: Quote?

    private var filteredQuotes: [Quote] {
        guard !searchText.isEmpty else { return quotes }
        return quotes.filter {
            $0.text.localizedCaseInsensitiveContains(searchText) ||
            ($0.book?.title.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if quotes.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredQuotes) { quote in
                            VStack(alignment: .leading, spacing: 8) {
                                QuoteCard(quote: quote)
                                    .contextMenu {
                                        Button {
                                            editingQuote = quote
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        Button(role: .destructive) {
                                            quotePendingDeletion = quote
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }

                                HStack(spacing: 12) {
                                    Button {
                                        editingQuote = quote
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(Theme.accentLight)

                                    Button(role: .destructive) {
                                        quotePendingDeletion = quote
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .buttonStyle(.plain)
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Quotes")
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
        .sheet(item: $editingQuote) { quote in
            EditQuoteView(quote: quote)
        }
        .confirmationDialog("Delete this quote?", isPresented: Binding(
            get: { quotePendingDeletion != nil },
            set: { if !$0 { quotePendingDeletion = nil } }
        ), titleVisibility: .visible) {
            Button("Delete Quote", role: .destructive) {
                if let quotePendingDeletion {
                    modelContext.delete(quotePendingDeletion)
                }
                quotePendingDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                quotePendingDeletion = nil
            }
        } message: {
            Text("This will remove the quote from your saved quotes.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .addNewQuote)) { _ in
            showAddQuote = true
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

private struct EditQuoteView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var quote: Quote

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let book = quote.book {
                            HStack(spacing: 8) {
                                Image(systemName: "book.fill")
                                    .foregroundStyle(Theme.accent)
                                Text(book.title)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Theme.accentLight)
                            }
                            .padding(12)
                            .background(Theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quote")
                                .font(.subheadline.bold())
                                .foregroundStyle(Theme.textSecondary)

                            TextEditor(text: $quote.text)
                                .scrollContentBackground(.hidden)
                                .foregroundStyle(Theme.textPrimary)
                                .frame(minHeight: 160)
                                .padding(12)
                                .background(Theme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .onChange(of: quote.text) {
                                    quote.needsSync = true
                                }
                        }

                        HStack {
                            Spacer()
                            Text("Created \(quote.dateCreated.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                    }
                    .padding()
                    .frame(maxWidth: 600)
                }
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Edit Quote")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        quote.text = quote.text.trimmingCharacters(in: .whitespacesAndNewlines)
                        quote.needsSync = true
                        dismiss()
                    }
                    .foregroundStyle(Theme.accent)
                    .disabled(quote.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 450, minHeight: 350)
    }
}
