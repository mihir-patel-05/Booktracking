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

    /// Returns minutes per day for the past 7 days, in display order Mon..Sun.
    private var weekMinutes: [Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // weekday: 1 = Sunday in Calendar; we want Monday-first.
        var days: [Date] = []
        for offset in (0..<7).reversed() {
            if let d = calendar.date(byAdding: .day, value: -offset, to: today) {
                days.append(d)
            }
        }
        return days.map { day -> Int in
            let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            return allSessions
                .filter { $0.startDate >= day && $0.startDate < next }
                .reduce(0) { $0 + $1.durationSeconds / 60 }
        }
    }

    /// Returns intensity (0, 0.5, 1) per day for the last 28 days, oldest first.
    private var heatmap: [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<28).reversed().map { offset -> Double in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return 0 }
            let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let mins = allSessions
                .filter { $0.startDate >= day && $0.startDate < next }
                .reduce(0) { $0 + $1.durationSeconds / 60 }
            if mins == 0 { return 0 }
            if mins < 30 { return 0.5 }
            return 1.0
        }
    }

    private var moodDistribution: [(MoodTag, Double)] {
        var counts: [MoodTag: Int] = [:]
        var total = 0
        for session in allSessions {
            for tag in session.moodTags {
                if let mood = MoodTag(rawValue: tag) {
                    counts[mood, default: 0] += 1
                    total += 1
                }
            }
        }
        guard total > 0 else { return [] }
        return counts
            .map { ($0.key, Double($0.value) / Double(total) * 100) }
            .sorted { $0.1 > $1.1 }
            .prefix(4)
            .map { ($0.0, $0.1) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if userStats == nil && allSessions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            header
                            levelCard
                            statGrid
                            weeklyChart
                            heatmapCard
                            if !moodDistribution.isEmpty { vibeProfileCard }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 28)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            #if os(iOS)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
        }
    }

    private var header: some View {
        HStack {
            Text("Stats")
                .font(.playfair(26, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
        }
        .padding(.bottom, 6)
    }

    // MARK: - Level Card

    private var levelCard: some View {
        let level = userStats?.currentLevel ?? .casualReader
        let xp = userStats?.totalXP ?? 0
        let progress = userStats?.levelProgress ?? 0
        let allLevels = ReaderLevel.allCases
        let currentIdx = allLevels.firstIndex(of: level) ?? 0
        let prev = currentIdx > 0 ? allLevels[currentIdx - 1].rawValue : "—"
        let next = currentIdx < allLevels.count - 1 ? allLevels[currentIdx + 1].rawValue : "Max"

        return VStack(spacing: 10) {
            Text("📚").font(.system(size: 40))
            Text(level.rawValue)
                .font(.playfair(22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("\(xp) XP · Next level at \(level.xpForNext)")
                .font(.dmSans(13))
                .foregroundStyle(Theme.accentLight)
                .padding(.bottom, 6)

            ProgressBarV2(value: progress, color: Theme.accent, height: 6)

            HStack {
                Text(prev)
                Spacer()
                Text(next)
            }
            .font(.dmSans(10))
            .foregroundStyle(Theme.textMuted)
            .padding(.top, 2)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .bannerCard(cornerRadius: 20)
    }

    // MARK: - 2x2 stat grid

    private var statGrid: some View {
        let stats = userStats
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            StatCard(title: "Current Streak",
                     value: "\(stats?.currentStreak ?? 0)d",
                     icon: "flame.fill",
                     iconColor: Theme.streak,
                     emoji: "🔥")
            StatCard(title: "Longest Streak",
                     value: "\(stats?.longestStreak ?? 0)d",
                     icon: "trophy.fill",
                     iconColor: Theme.accent,
                     emoji: "🏆")
            StatCard(title: "Total Sessions",
                     value: "\(allSessions.count)",
                     icon: "timer",
                     iconColor: Theme.accentLight,
                     emoji: "⏱")
            StatCard(title: "Hours Read",
                     value: "\(totalReadingMinutes / 60)h",
                     icon: "book.fill",
                     iconColor: Theme.success,
                     emoji: "📖")
        }
    }

    // MARK: - Weekly chart

    private var weeklyChart: some View {
        let mins = weekMinutes
        let maxMin = max(mins.max() ?? 0, 1)
        let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

        return VStack(alignment: .leading, spacing: 0) {
            SectionLabel("This Week")
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    VStack(spacing: 6) {
                        let value = mins[i]
                        let height: CGFloat = max(CGFloat(value) / CGFloat(maxMin) * 70, value > 0 ? 6 : 2)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(value > 0
                                ? AnyShapeStyle(LinearGradient(colors: [Theme.accentLight, Theme.accent], startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(Theme.cardBackgroundLight))
                            .frame(height: height)
                            .shadow(color: value > 0 ? Theme.accentGlow : .clear, radius: 4)
                        Text(dayLabels[i])
                            .font(.dmSans(10))
                            .foregroundStyle(Theme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 88)
        }
        .padding(16)
        .designCard(cornerRadius: 18)
    }

    // MARK: - 28-day heatmap

    private var heatmapCard: some View {
        let cells = heatmap
        return VStack(alignment: .leading, spacing: 0) {
            SectionLabel("28-Day Activity")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 5) {
                ForEach(0..<cells.count, id: \.self) { i in
                    let v = cells[i]
                    RoundedRectangle(cornerRadius: 4)
                        .fill(v == 0 ? Theme.cardBackgroundLight : (v == 0.5 ? Theme.accent.opacity(0.45) : Theme.accent))
                        .aspectRatio(1, contentMode: .fit)
                        .shadow(color: v == 1 ? Theme.accentGlow : .clear, radius: 3)
                }
            }
            .padding(.bottom, 10)

            HStack(spacing: 6) {
                Spacer()
                Text("Less")
                    .font(.dmSans(9))
                    .foregroundStyle(Theme.textMuted)
                ForEach([Theme.cardBackgroundLight, Theme.accent.opacity(0.45), Theme.accent], id: \.self) { c in
                    RoundedRectangle(cornerRadius: 3).fill(c).frame(width: 10, height: 10)
                }
                Text("More")
                    .font(.dmSans(9))
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding(16)
        .designCard(cornerRadius: 18)
    }

    // MARK: - Vibe profile

    private var vibeProfileCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("Reading Vibe Profile")
            VStack(spacing: 12) {
                ForEach(moodDistribution, id: \.0) { (mood, pct) in
                    VStack(spacing: 5) {
                        HStack {
                            Text(mood.rawValue)
                                .font(.dmSans(13, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text("\(Int(pct))%")
                                .font(.dmSans(12, weight: .semibold))
                                .foregroundStyle(mood.color)
                        }
                        ProgressBarV2(value: pct, color: mood.color, height: 5)
                    }
                }
            }
            .padding(.bottom, 14)

            HStack {
                Text("Your top moods reflect what's been resonating most across recent sessions.")
                    .font(.dmSans(12))
                    .italic()
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.accent.opacity(0.06))
            .overlay(
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 3),
                alignment: .leading
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .designCard(cornerRadius: 18)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 18) {
            Text("📊").font(.system(size: 48))
            Text("No Stats Yet")
                .font(.playfair(22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Complete your first reading session to start tracking your progress.")
                .font(.dmSans(14))
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
