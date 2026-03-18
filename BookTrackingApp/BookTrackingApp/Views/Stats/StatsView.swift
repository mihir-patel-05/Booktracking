import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var stats: [UserStats]
    @Query private var allBooks: [Book]
    @Query(sort: \ReadingSession.startDate, order: .reverse) private var allSessions: [ReadingSession]

    private var userStats: UserStats? { stats.first }

    private var completedCount: Int {
        allBooks.filter { $0.status == .completed }.count
    }

    private var totalReadingMinutes: Int {
        allSessions.reduce(0) { $0 + $1.durationSeconds } / 60
    }

    private var formattedReadingTime: String {
        let hours = totalReadingMinutes / 60
        let mins = totalReadingMinutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if userStats == nil && allSessions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            levelCard
                            streakRow
                            readingStatsRow
                            booksSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Stats")
            #if os(iOS)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
        }
    }

    // MARK: - Level Card

    private var levelCard: some View {
        let level = userStats?.currentLevel ?? .casualReader
        let xp = userStats?.totalXP ?? 0
        let progress = userStats?.levelProgress ?? 0

        return VStack(spacing: 12) {
            Image(systemName: level.icon)
                .font(.system(size: 40))
                .foregroundStyle(Theme.accent)

            Text(level.rawValue)
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)

            ProgressBar(
                progress: progress,
                height: 8,
                foregroundColor: Theme.accent
            )

            Text("\(xp) / \(level.xpForNext) XP")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Streak Row

    private var streakRow: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Current Streak",
                value: "\(userStats?.currentStreak ?? 0) days",
                icon: "flame.fill",
                iconColor: Theme.streak
            )
            StatCard(
                title: "Longest Streak",
                value: "\(userStats?.longestStreak ?? 0) days",
                icon: "flame.fill",
                iconColor: Theme.accent
            )
        }
    }

    // MARK: - Reading Stats Row

    private var readingStatsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Sessions",
                value: "\(allSessions.count)",
                icon: "timer"
            )
            StatCard(
                title: "Reading Time",
                value: formattedReadingTime,
                icon: "clock.fill"
            )
        }
    }

    // MARK: - Books Section

    private var booksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Books")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            StatCard(
                title: "Books Completed",
                value: "\(completedCount)",
                icon: "checkmark.circle.fill",
                iconColor: Theme.success
            )

            VStack(spacing: 0) {
                ForEach(BookStatus.allCases, id: \.self) { status in
                    let count = allBooks.filter { $0.status == status }.count
                    HStack {
                        Image(systemName: status.icon)
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                            .frame(width: 24)
                        Text(status.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text("\(count)")
                            .font(.subheadline.bold())
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if status != BookStatus.allCases.last {
                        Divider()
                            .background(Theme.cardBackgroundLight)
                    }
                }
            }
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)

            Text("No Stats Yet")
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)

            Text("Complete your first reading session to start tracking your progress.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [Book.self, ReadingSession.self, UserStats.self])
        .preferredColorScheme(.dark)
}
