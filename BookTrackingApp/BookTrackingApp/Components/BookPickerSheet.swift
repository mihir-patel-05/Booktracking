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
                    VStack(spacing: 14) {
                        Text("📚").font(.system(size: 38))
                        Text("No books found")
                            .font(.dmSans(14))
                            .foregroundStyle(Theme.textSecondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredBooks) { book in
                                Button {
                                    onSelect(book)
                                    dismiss()
                                } label: {
                                    pickerRow(book)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                }
            }
            .navigationTitle("Select Book")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.accentLight)
                }
            }
        }
    }

    private func pickerRow(_ book: Book) -> some View {
        HStack(spacing: 12) {
            BookCoverView(book: book, size: .sm)
            VStack(alignment: .leading, spacing: 3) {
                Text(book.title)
                    .font(.dmSans(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(book.author)
                    .font(.dmSans(11))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textMuted)
        }
        .padding(12)
        .designCard(cornerRadius: 14)
    }
}
