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

            VStack(alignment: .leading, spacing: 0) {
                Text("Library")
                    .font(.playfair(26, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                StatusFilterPills(selected: $selectedStatus)
                    .padding(.bottom, 12)

                if filteredBooks.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                            spacing: 12
                        ) {
                            ForEach(filteredBooks) { book in
                                NavigationLink(value: book) {
                                    libraryCard(book)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        #if os(iOS)
        .toolbarColorScheme(.dark, for: .navigationBar)
        #endif
        .navigationDestination(for: Book.self) { book in
            BookDetailView(book: book)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Theme.accentLight)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            BookSearchView()
        }
    }

    private func libraryCard(_ book: Book) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Spacer()
                BookCoverView(book: book, size: .lg)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(book.title)
                    .font(.dmSans(13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                Text(book.author)
                    .font(.dmSans(11))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }

            if book.status == .currentlyReading {
                ProgressBarV2(value: book.progressPercentage, height: 4)
                Text("\(Int(book.progressPercentage * 100))%")
                    .font(.dmSans(11, weight: .semibold))
                    .foregroundStyle(Theme.accentLight)
            } else {
                Text(book.status.rawValue)
                    .font(.dmSans(10, weight: .semibold))
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .designCard(cornerRadius: 18)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("📚").font(.system(size: 40))
            Text(selectedStatus == nil ? "No books yet" : "No \(selectedStatus!.rawValue.lowercased()) books")
                .font(.playfair(18, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            if selectedStatus == nil {
                Text("Tap + to add your first book")
                    .font(.dmSans(13))
                    .foregroundStyle(Theme.textMuted)
            }
        }
    }
}
