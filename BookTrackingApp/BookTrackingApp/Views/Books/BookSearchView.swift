import SwiftUI

struct BookSearchView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var results: [GoogleBookItem] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var selectedDoc: GoogleBookItem?
    @State private var showAddSheet = false
    @State private var showManualAdd = false

    private let searchService = BookSearchService()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                    if isSearching {
                        Spacer()
                        ProgressView().tint(Theme.accent)
                        Spacer()
                    } else if results.isEmpty && !query.isEmpty {
                        Spacer()
                        emptyResults(emoji: "🔍", text: "No results found")
                        Spacer()
                    } else if results.isEmpty {
                        Spacer()
                        emptyResults(emoji: "📖", text: "Search by title or author")
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(results) { doc in
                                    Button {
                                        selectedDoc = doc
                                        showAddSheet = true
                                    } label: {
                                        SearchResultRow(doc: doc)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationTitle("Search Books")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.accentLight)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Manual") { showManualAdd = true }
                        .foregroundStyle(Theme.accentLight)
                }
            }
            .sheet(isPresented: $showAddSheet) {
                if let doc = selectedDoc {
                    AddBookView(prefill: doc)
                }
            }
            .sheet(isPresented: $showManualAdd) {
                AddBookView()
            }
            .onChange(of: query) { _, newValue in
                searchTask?.cancel()
                let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else {
                    results = []
                    isSearching = false
                    return
                }

                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    guard !Task.isCancelled else { return }

                    isSearching = true
                    do {
                        let docs = try await searchService.search(query: trimmed)
                        if !Task.isCancelled {
                            results = docs
                        }
                    } catch {
                        if !Task.isCancelled {
                            results = []
                        }
                    }
                    if !Task.isCancelled {
                        isSearching = false
                    }
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textMuted)
            TextField("Search books...", text: $query)
                .font(.dmSans(14))
                .foregroundStyle(Theme.textPrimary)
                .tint(Theme.accentLight)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button {
                    query = ""
                    results = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .designCard(cornerRadius: 12)
    }

    private func emptyResults(emoji: String, text: String) -> some View {
        VStack(spacing: 12) {
            Text(emoji).font(.system(size: 42))
            Text(text)
                .font(.dmSans(14))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

private struct SearchResultRow: View {
    let doc: GoogleBookItem

    var body: some View {
        HStack(spacing: 12) {
            BookCoverView(
                title: doc.volumeInfo.title,
                coverURL: doc.coverURL,
                paletteSeed: doc.id,
                size: .sm
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(doc.volumeInfo.title)
                    .font(.dmSans(13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(doc.authorDisplay)
                    .font(.dmSans(11))
                    .foregroundStyle(Theme.textSecondary)

                if doc.pageCount > 0 {
                    Text("\(doc.pageCount) pages")
                        .font(.dmSans(10))
                        .foregroundStyle(Theme.textMuted)
                }
            }

            Spacer()

            Image(systemName: "plus.circle.fill")
                .foregroundStyle(Theme.accentLight)
                .font(.system(size: 22))
        }
        .padding(12)
        .designCard(cornerRadius: 14)
    }
}
