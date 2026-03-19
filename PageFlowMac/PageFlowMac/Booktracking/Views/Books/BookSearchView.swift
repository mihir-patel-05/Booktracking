import SwiftUI

struct BookSearchView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var results: [OpenLibraryDoc] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var selectedDoc: OpenLibraryDoc?
    @State private var showAddSheet = false
    @State private var showManualAdd = false

    private let searchService = BookSearchService()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar

                    if isSearching {
                        Spacer()
                        ProgressView()
                            .tint(Theme.accent)
                        Spacer()
                    } else if results.isEmpty && !query.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundStyle(Theme.textMuted)
                            Text("No results found")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                    } else if results.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "text.magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundStyle(Theme.textMuted)
                            Text("Search by title or author")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                    } else {
                        resultsList
                    }
                }
            }
            .navigationTitle("Search Books")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Manual") { showManualAdd = true }
                        .foregroundStyle(Theme.accent)
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
        .frame(minWidth: 500, minHeight: 400)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.textMuted)
            TextField("Search books...", text: $query)
                .foregroundStyle(Theme.textPrimary)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button {
                    query = ""
                    results = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
        .padding(12)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
    }

    private var resultsList: some View {
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
            .padding(.horizontal)
        }
    }
}

private struct SearchResultRow: View {
    let doc: OpenLibraryDoc

    var body: some View {
        HStack(spacing: 12) {
            if let urlString = doc.coverURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        placeholder
                    }
                }
                .frame(width: 44, height: 66)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                placeholder
                    .frame(width: 44, height: 66)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(doc.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(doc.authorDisplay)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)

                if doc.pageCount > 0 {
                    Text("\(doc.pageCount) pages")
                        .font(.caption2)
                        .foregroundStyle(Theme.textMuted)
                }
            }

            Spacer()

            Image(systemName: "plus.circle")
                .foregroundStyle(Theme.accent)
                .font(.title3)
        }
        .padding(12)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Theme.cardBackgroundLight)
            .overlay(
                Image(systemName: "book.closed")
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            )
    }
}
