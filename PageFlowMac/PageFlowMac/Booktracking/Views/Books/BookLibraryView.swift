import SwiftUI
import SwiftData

struct BookLibraryView: View {
    @Query(sort: \Book.dateAdded, order: .reverse) private var allBooks: [Book]
    @State private var selectedStatus: BookStatus?
    @State private var showAddSheet = false

    private var filteredBooks: [Book] {
        guard let status = selectedStatus else { return allBooks }
        return allBooks.filter { $0.status == status }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                StatusFilterPills(selected: $selectedStatus)
                    .padding(.vertical, 8)

                if filteredBooks.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.textMuted)
                        Text(selectedStatus == nil ? "No books yet" : "No \(selectedStatus!.rawValue.lowercased()) books")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                        if selectedStatus == nil {
                            Text("Click + to add your first book")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredBooks) { book in
                                NavigationLink(value: book) {
                                    BookCard(book: book)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
            }
        }
        .navigationTitle("My Library")
        .navigationDestination(for: Book.self) { book in
            BookDetailView(book: book)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            BookSearchView()
        }
    }
}
