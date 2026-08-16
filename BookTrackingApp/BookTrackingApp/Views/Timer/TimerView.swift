import SwiftUI
import SwiftData

private enum TimerPhase {
    case setup
    case active
    case postSession
}

struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthService.self) private var authService
    @Environment(NotificationService.self) private var notificationService
    @Environment(\.scenePhase) private var scenePhase

    @Query(filter: #Predicate<Book> { $0.statusRawValue == "Currently Reading" },
           sort: \Book.dateAdded, order: .reverse)
    private var currentlyReadingBooks: [Book]

    @Query private var stats: [UserStats]

    @State private var phase: TimerPhase = .setup

    @Environment(TimerService.self) private var timerService
    @State private var customMinutesInput = ""

    @State private var selectedBook: Book?

    #if os(macOS)
    private let timerCircleSize: CGFloat = 320
    private let controlButtonSize: CGFloat = 72
    #else
    private let timerCircleSize: CGFloat = 240
    private let controlButtonSize: CGFloat = 64
    #endif

    @State private var sessionSaved = false
    @State private var earnedXP = 0
    @State private var savedSession: ReadingSession?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                switch phase {
                case .setup:
                    setupView
                case .active:
                    activeView
                case .postSession:
                    postSessionView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            #if os(iOS)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background, .inactive:
                timerService.handleBackground()
            case .active:
                timerService.handleForeground()
                if timerService.isCompleted && phase == .active {
                    notificationService.cancelTimerNotification()
                    transitionToPostSession()
                }
            @unknown default:
                break
            }
        }
        .onChange(of: timerService.isCompleted) { _, completed in
            if completed && phase == .active {
                notificationService.cancelTimerNotification()
                transitionToPostSession()
            }
        }
    }

    // MARK: - Setup View

    private var setupView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reading Timer")
                        .font(.playfair(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Focus on one book, one session.")
                        .font(.dmSans(13))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.bottom, 22)

                SectionLabel("Select Book")
                if currentlyReadingBooks.isEmpty {
                    emptyBookCard
                        .padding(.bottom, 24)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(currentlyReadingBooks) { book in
                                bookSelectorCard(book)
                            }
                        }
                        .padding(.bottom, 2)
                    }
                    .padding(.bottom, 24)
                }

                SectionLabel("Duration")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(TimerPreset.allCases, id: \.self) { preset in
                        let selected = timerService.selectedPreset == preset
                        Button {
                            timerService.selectPreset(preset)
                            customMinutesInput = ""
                        } label: {
                            Text(preset.label)
                                .font(.dmSans(14, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(selected ? Theme.accent.opacity(0.20) : Theme.cardBackground)
                                .foregroundStyle(selected ? Theme.accentLight : Theme.textSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selected ? Theme.accent : .clear, lineWidth: 2)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 14)

                HStack(spacing: 8) {
                    TextField("Custom (mins)", text: $customMinutesInput)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .font(.dmSans(14))
                        .foregroundStyle(Theme.textPrimary)
                        .tint(Theme.accentLight)
                        .padding(12)
                        .designCard(cornerRadius: 12)

                    Button {
                        timerService.setCustomMinutes(customMinutesInput)
                    } label: {
                        Text("Set")
                            .font(.dmSans(14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 18)

                if let book = selectedBook {
                    sessionPreview(book: book)
                        .padding(.bottom, 18)
                }

                Button {
                    startTimer()
                } label: {
                    HStack(spacing: 8) {
                        if selectedBook != nil {
                            Image(systemName: "play.fill")
                            Text("Start Session")
                        } else {
                            Text("Select a book to begin")
                        }
                    }
                }
                .buttonStyle(PrimaryGradientButtonStyle(enabled: selectedBook != nil))
                .disabled(selectedBook == nil)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
    }

    private var emptyBookCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 32))
                .foregroundStyle(Theme.textMuted)
            Text("No books currently being read")
                .font(.dmSans(14))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .designCard(cornerRadius: 14)
    }

    private func bookSelectorCard(_ book: Book) -> some View {
        let selected = selectedBook?.id == book.id
        return Button {
            selectedBook = book
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                BookCoverView(book: book, size: .sm)
                Text(book.title)
                    .font(.dmSans(12, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                Text(book.author)
                    .font(.dmSans(10))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(width: 124, alignment: .leading)
            .background(selected ? Theme.accent.opacity(0.18) : Theme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? Theme.accent : Theme.border, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func sessionPreview(book: Book) -> some View {
        HStack(spacing: 12) {
            BookCoverView(book: book, size: .sm)
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.dmSans(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text("\(Int(book.progressPercentage * 100))% complete · \(timerService.totalSeconds / 60) min session")
                    .font(.dmSans(11))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .designCard(cornerRadius: 14)
    }

    // MARK: - Active View

    private var activeView: some View {
        VStack(spacing: 0) {
            if let book = selectedBook {
                HStack(spacing: 10) {
                    BookCoverView(book: book, size: .sm)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(book.title)
                            .font(.dmSans(13, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                        Text("Focus session · \(timerService.totalSeconds / 60)m")
                            .font(.dmSans(11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Text(timerService.isRunning ? "● Live" : "⏸ Paused")
                        .font(.dmSans(12, weight: .semibold))
                        .foregroundStyle(timerService.isRunning ? Theme.success : Theme.streak)
                }
                .padding(10)
                .designCard(cornerRadius: 12)
                .padding(.horizontal, 24)
                .padding(.top, 30)
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Theme.cardBackgroundLight, lineWidth: 10)
                    .frame(width: timerCircleSize, height: timerCircleSize)

                Circle()
                    .trim(from: 0, to: timerService.progress)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: timerCircleSize, height: timerCircleSize)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Theme.accent.opacity(0.6), radius: 8)
                    .animation(.linear(duration: 0.8), value: timerService.progress)

                VStack(spacing: 8) {
                    Text(timerService.formattedTime)
                        .font(.dmSans(48, weight: .light))
                        .foregroundStyle(Theme.textPrimary)
                        .tracking(-1)
                    Text("remaining")
                        .font(.dmSans(12))
                        .foregroundStyle(Theme.textMuted)
                }
            }

            Spacer()

            HStack(spacing: 24) {
                Button {
                    togglePause()
                } label: {
                    Image(systemName: timerService.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accentLight)
                        .frame(width: controlButtonSize, height: controlButtonSize)
                        .background(Theme.accent.opacity(0.15))
                        .overlay(
                            Circle().stroke(Theme.accent, lineWidth: 2)
                        )
                        .clipShape(Circle())
                        .shadow(color: Theme.accentGlow, radius: 14)
                }
                .buttonStyle(.plain)

                Button {
                    stopTimer()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.error)
                        .frame(width: controlButtonSize, height: controlButtonSize)
                        .background(Theme.error.opacity(0.10))
                        .overlay(
                            Circle().stroke(Theme.error.opacity(0.5), lineWidth: 2)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Post Session View

    @ViewBuilder
    private var postSessionView: some View {
        if sessionSaved {
            xpRewardView
        } else if let book = selectedBook {
            JournalFlowView(
                book: book,
                timerService: timerService,
                onSave: { session, xp in
                    savedSession = session
                    earnedXP = xp
                    updateUserStats(xp: xp)
                    withAnimation { sessionSaved = true }
                }
            )
        }
    }

    private var xpRewardView: some View {
        VStack(spacing: 0) {
            Spacer()
            Text("🎉").font(.system(size: 56))
                .padding(.bottom, 12)
            Text("+\(earnedXP) XP")
                .font(.playfair(32, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.bottom, 4)
            Text("Session saved to your library")
                .font(.dmSans(14))
                .foregroundStyle(Theme.textSecondary)
                .padding(.bottom, 28)

            Button {
                resetToSetup()
            } label: {
                Text("Done")
                    .font(.dmSans(15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .designCard(cornerRadius: 14)
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    // MARK: - Timer Actions

    private func startTimer() {
        timerService.start()
        if let endDate = timerService.targetEndDate {
            notificationService.scheduleTimerCompletion(at: endDate)
        }
        withAnimation { phase = .active }
    }

    private func togglePause() {
        if timerService.isRunning {
            timerService.pause()
            notificationService.cancelTimerNotification()
        } else {
            timerService.resume()
            if let endDate = timerService.targetEndDate {
                notificationService.scheduleTimerCompletion(at: endDate)
            }
        }
    }

    private func stopTimer() {
        timerService.stop()
        notificationService.cancelTimerNotification()
        transitionToPostSession()
    }

    private func transitionToPostSession() {
        withAnimation { phase = .postSession }
    }

    // MARK: - Stats

    private func updateUserStats(xp: Int) {
        let userStats: UserStats
        if let existing = stats.first {
            userStats = existing
        } else {
            userStats = UserStats()
            userStats.supabaseUserId = authService.currentUserId
            modelContext.insert(userStats)
        }
        userStats.totalXP += xp
        updateStreak(userStats)
        userStats.needsSync = true
    }

    private func updateStreak(_ stats: UserStats) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = stats.lastSessionDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysBetween == 1 {
                stats.currentStreak += 1
            } else if daysBetween > 1 {
                stats.currentStreak = 1
            }
        } else {
            stats.currentStreak = 1
        }

        stats.longestStreak = max(stats.longestStreak, stats.currentStreak)
        stats.lastSessionDate = Date()
    }

    private func resetToSetup() {
        selectedBook = nil
        timerService.reset()
        customMinutesInput = ""
        sessionSaved = false
        earnedXP = 0
        savedSession = nil
        withAnimation { phase = .setup }
    }
}

#Preview {
    TimerView()
        .modelContainer(for: [Book.self, ReadingSession.self, UserStats.self, SessionNote.self, Quote.self])
        .environment(AuthService())
        .environment(NotificationService())
        .environment(TimerService())
        .preferredColorScheme(.dark)
}
