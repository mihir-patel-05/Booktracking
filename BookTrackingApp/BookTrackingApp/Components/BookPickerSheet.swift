import SwiftUI
import SwiftData

struct BookPickerSheet: View {
    @Query(sort: \Book.dateAdded, order: .reverse) private var allBooks: [Book]
    @Environment(\.dismiss) private var dismiss
    let filterStatus: BookStatus?
    let onSelect: (Book) -> Void

    var filteredBooks: [Book] {
        guard let status = filterStatus else { return allBooks }
        return allBooks.filter { $0.status == status }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if filteredBooks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.textMuted)
                        Text("No books found")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredBooks) { book in
                                Button {
                                    onSelect(book)
                                    dismiss()
                                } label: {
                                    BookCard(book: book)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Select Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }
}
