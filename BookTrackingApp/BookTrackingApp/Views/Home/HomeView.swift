import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(filter: #Predicate<Book> { $0.statusRawValue == "Currently Reading" },
           sort: \Book.dateAdded, order: .reverse)
    private var currentlyReading: [Book]

    @Query(sort: \Book.dateAdded, order: .reverse)
    private var allBooks: [Book]

    @State private var showAddSheet = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good Morning"
        } else if hour < 17 {
            return "Good Afternoon"
        } else {
            return "Good Evening"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        greetingSection
                        currentlyReadingSection
                        librarySection
                    }
                    .padding()
                }
            }
            .navigationTitle("PageFlow")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                BookSearchView()
            }
        }
    }

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.title.bold())
                .foregroundStyle(Theme.textPrimary)

            Text("\(allBooks.count) book\(allBooks.count == 1 ? "" : "s") in your library")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var currentlyReadingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Currently Reading")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            if currentlyReading.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "book")
                            .font(.title)
                            .foregroundStyle(Theme.textMuted)
                        Text("No books in progress")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                        Button("Add a book") { showAddSheet = true }
                            .font(.caption.bold())
                            .foregroundStyle(Theme.accent)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(currentlyReading) { book in
                            NavigationLink {
                                BookDetailView(book: book)
                            } label: {
                                BookCard(book: book, compact: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var librarySection: some View {
        NavigationLink {
            BookLibraryView()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Library")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(allBooks.count) book\(allBooks.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Text("See All")
                    .font(.subheadline)
                    .foregroundStyle(Theme.accent)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
            }
            .padding()
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Book.self, inMemory: true)
        .preferredColorScheme(.dark)
}
