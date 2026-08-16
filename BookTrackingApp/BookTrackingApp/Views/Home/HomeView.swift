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
        if hour < 12 { return "Good Morning" }
        if hour < 17 { return "Good Afternoon" }
        return "Good Evening"
    }

    private var weekMinutes: Int {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return recentSessions
            .filter { $0.startDate >= weekStart }
            .reduce(0) { $0 + $1.durationSeconds / 60 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        greetingSection
                            .padding(.top, 16)
                            .padding(.horizontal, 20)

                        if let userStats = stats.first {
                            streakBanner(userStats: userStats)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                        }

                        currentlyReadingSection
                            .padding(.top, 24)

                        if !recentSessions.isEmpty {
                            recentSessionsSection
                                .padding(.top, 22)
                                .padding(.horizontal, 20)
                        }

                        quickStatsRow
                            .padding(.top, 16)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            #if os(iOS)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
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
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("PAGEFLOW")
                .font(.dmSans(11, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(Theme.textMuted)

            Text("\(greeting) 👋")
                .font(.playfair(28, weight: .bold))
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: 4) {
                Text("You've read")
                    .font(.dmSans(13))
                    .foregroundStyle(Theme.textSecondary)
                Text("\(weekMinutes / 60)h \(weekMinutes % 60)m")
                    .font(.dmSans(13, weight: .semibold))
                    .foregroundStyle(Theme.accentLight)
                Text("this week")
                    .font(.dmSans(13))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Streak Banner

    private func streakBanner(userStats: UserStats) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.streak.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Text("🔥").font(.system(size: 26))
                }
                .shadow(color: Theme.streak.opacity(0.3), radius: 12)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(userStats.currentStreak)-day streak")
                        .font(.playfair(20, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Longest: \(userStats.longestStreak) days · Keep going!")
                        .font(.dmSans(12))
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(userStats.currentLevel.rawValue)
                        .font(.dmSans(13, weight: .semibold))
                        .foregroundStyle(Theme.accentLight)
                    Text("\(userStats.totalXP) XP")
                        .font(.dmSans(12))
                        .foregroundStyle(Theme.accent)
                }
            }

            VStack(spacing: 5) {
                HStack {
                    Text("Level progress")
                    Spacer()
                    Text("\(userStats.totalXP) / \(userStats.currentLevel.xpForNext) XP")
                }
                .font(.dmSans(10))
                .foregroundStyle(Theme.textMuted)

                ProgressBarV2(value: userStats.levelProgress, color: Theme.accent, height: 5)
            }
            .padding(.top, 12)
        }
        .padding(18)
        .bannerCard(cornerRadius: 18)
    }

    // MARK: - Currently Reading

    private var currentlyReadingSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SectionLabel("Currently Reading", bottomPadding: 0)
                Spacer()
                NavigationLink {
                    BookLibraryView()
                } label: {
                    Text("See all")
                        .font(.dmSans(11, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            if currentlyReading.isEmpty {
                emptyReadingCard
                    .padding(.horizontal, 20)
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
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)
                }
            }
        }
    }

    private var emptyReadingCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "book")
                .font(.system(size: 28))
                .foregroundStyle(Theme.textMuted)
            Text("No books in progress")
                .font(.dmSans(13))
                .foregroundStyle(Theme.textSecondary)
            Button("Add a book") { showAddSheet = true }
                .font(.dmSans(12, weight: .semibold))
                .foregroundStyle(Theme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .designCard(cornerRadius: 16)
    }

    // MARK: - Recent Sessions

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("Recent Sessions")

            VStack(spacing: 8) {
                ForEach(Array(recentSessions.prefix(3))) { session in
                    sessionRow(session: session)
                }
            }
        }
    }

    private func sessionRow(session: ReadingSession) -> some View {
        HStack(spacing: 12) {
            if let book = session.book {
                BookCoverView(book: book, size: .sm)
            } else {
                placeholderSquare
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(session.book?.title ?? "Unknown Book")
                    .font(.dmSans(13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text("\(session.durationSeconds / 60) min · \(session.startDate.formatted(.dateTime.month(.abbreviated).day()))")
                    .font(.dmSans(11))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer(minLength: 8)

            HStack(spacing: 4) {
                ForEach(session.moodTags.prefix(3), id: \.self) { tagString in
                    if let mood = MoodTag(rawValue: tagString) {
                        Circle()
                            .fill(mood.color)
                            .frame(width: 8, height: 8)
                            .shadow(color: mood.color.opacity(0.5), radius: 3)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .designCard(cornerRadius: 14)
    }

    private var placeholderSquare: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Theme.cardBackgroundLight)
            .frame(width: 42, height: 60)
            .overlay(
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(Theme.textMuted)
            )
    }

    // MARK: - Quick Stats

    private var quickStatsRow: some View {
        let readingCount = currentlyReading.count
        let sessionCount = recentSessions.count
        let totalMins = recentSessions.reduce(0) { $0 + $1.durationSeconds / 60 }
        let hours = totalMins / 60

        return HStack(spacing: 10) {
            quickStatCard(emoji: "📚", value: "\(readingCount)", label: "Reading")
            quickStatCard(emoji: "⏱", value: "\(sessionCount)", label: "Sessions")
            quickStatCard(emoji: "🕐", value: "\(hours)h", label: "Read")
        }
    }

    private func quickStatCard(emoji: String, value: String, label: String) -> some View {
        VStack(spacing: 5) {
            Text(emoji).font(.system(size: 18))
            Text(value)
                .font(.playfair(20, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.dmSans(10))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .designCard(cornerRadius: 14)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Book.self, ReadingSession.self, UserStats.self], inMemory: true)
        .preferredColorScheme(.dark)
}
