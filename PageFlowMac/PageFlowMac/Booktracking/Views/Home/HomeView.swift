import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(filter: #Predicate<Book> { $0.statusRawValue == "Currently Reading" },
           sort: \Book.dateAdded, order: .reverse)
    private var currentlyReading: [Book]

    @Query(sort: \Book.dateAdded, order: .reverse)
    private var allBooks: [Book]

    @Query(sort: \ReadingSession.startDate, order: .reverse)
    private var recentSessions: [ReadingSession]

    @Query private var stats: [UserStats]

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
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    greetingSection
                    if stats.first != nil { streakSection }
                    currentlyReadingSection
                    if !recentSessions.isEmpty { recentSessionsSection }
                    librarySection
                }
                .padding()
                .frame(maxWidth: 700, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("PageFlow")
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
        .onReceive(NotificationCenter.default.publisher(for: .addNewBook)) { _ in
            showAddSheet = true
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

    // MARK: - Streak Section

    private var streakSection: some View {
        let userStats = stats.first!
        return HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(Theme.streak)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(userStats.currentStreak) day streak")
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.textPrimary)

                HStack(spacing: 8) {
                    Image(systemName: userStats.currentLevel.icon)
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                    Text(userStats.currentLevel.rawValue)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(userStats.totalXP) XP")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.accent)
                ProgressBar(
                    progress: userStats.levelProgress,
                    height: 4,
                    foregroundColor: Theme.accent
                )
                .frame(width: 60)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Recent Sessions Section

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            ForEach(Array(recentSessions.prefix(3))) { session in
                HStack(spacing: 12) {
                    Image(systemName: "timer")
                        .foregroundStyle(Theme.accent)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.book?.title ?? "Unknown Book")
                            .font(.subheadline.bold())
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            Text("\(session.durationSeconds / 60) min")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)

                            Text(session.startDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                    }

                    Spacer()

                    // Mood dots
                    HStack(spacing: 2) {
                        ForEach(session.moodTags.prefix(3), id: \.self) { tagString in
                            if let mood = MoodTag(rawValue: tagString) {
                                Circle()
                                    .fill(mood.color)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
