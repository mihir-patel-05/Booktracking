import SwiftUI
import SwiftData

// MARK: - Timer Phase

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

    // Phase
    @State private var phase: TimerPhase = .setup

    // Timer service (local — only used by this view)
    @State private var timerService = TimerService()
    @State private var customMinutesInput = ""

    // Book selection
    @State private var selectedBook: Book?

    // Post-session state
    @State private var selectedMoodTags: Set<MoodTag> = []
    @State private var reflectionPrompt = ""
    @State private var reflectionText = ""
    @State private var sessionSaved = false
    @State private var earnedXP = 0

    // Sheets
    @State private var showAddNote = false
    @State private var showAddQuote = false
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
            .navigationTitle("Timer")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                timerService.handleBackground()
            case .active:
                timerService.handleForeground()
                if timerService.isCompleted && phase == .active {
                    notificationService.cancelTimerNotification()
                    transitionToPostSession()
                }
            default:
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
            VStack(spacing: 24) {
                // Book Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select a Book")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)

                    if currentlyReadingBooks.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 32))
                                .foregroundStyle(Theme.textMuted)
                            Text("No books currently being read")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(currentlyReadingBooks) { book in
                                    Button {
                                        selectedBook = book
                                    } label: {
                                        BookCard(book: book, compact: true)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .strokeBorder(
                                                        selectedBook?.id == book.id ? Theme.accent : Color.clear,
                                                        lineWidth: 2
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                // Timer Presets
                VStack(alignment: .leading, spacing: 12) {
                    Text("Duration")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)

                    HStack(spacing: 10) {
                        ForEach(TimerPreset.allCases, id: \.self) { preset in
                            Button {
                                timerService.selectPreset(preset)
                                customMinutesInput = ""
                            } label: {
                                Text(preset.label)
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(timerService.selectedPreset == preset ? Theme.accent : Theme.cardBackground)
                                    .foregroundStyle(timerService.selectedPreset == preset ? .white : Theme.textSecondary)
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    // Custom time
                    HStack(spacing: 8) {
                        TextField("Custom", text: $customMinutesInput)
                            .keyboardType(.numberPad)
                            .foregroundStyle(Theme.textPrimary)
                            .padding(12)
                            .background(Theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            timerService.setCustomMinutes(customMinutesInput)
                        } label: {
                            Text("Set")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Theme.accent)
                                .clipShape(Capsule())
                        }
                    }
                }

                // Start Button
                Button {
                    startTimer()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Start Session")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selectedBook != nil ? Theme.accent : Theme.cardBackgroundLight)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(selectedBook == nil)
            }
            .padding()
        }
    }

    // MARK: - Active View

    private var activeView: some View {
        VStack(spacing: 32) {
            // Book info
            if let book = selectedBook {
                HStack(spacing: 10) {
                    Image(systemName: "book.fill")
                        .foregroundStyle(Theme.accent)
                    Text(book.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                }
                .padding(12)
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Spacer()

            // Circular Timer
            ZStack {
                Circle()
                    .stroke(Theme.cardBackgroundLight, lineWidth: 8)
                    .frame(width: 220, height: 220)

                Circle()
                    .trim(from: 0, to: timerService.progress)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerService.progress)

                VStack(spacing: 4) {
                    Text(timerService.formattedTime)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary)
                    Text("remaining")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
            }

            Spacer()

            // Controls
            HStack(spacing: 24) {
                Button {
                    togglePause()
                } label: {
                    Image(systemName: timerService.isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(Theme.accent)
                        .clipShape(Circle())
                }

                Button {
                    stopTimer()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(Theme.error)
                        .clipShape(Circle())
                }
            }
            .padding(.bottom, 40)
        }
        .padding()
    }

    // MARK: - Post Session View

    private var postSessionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if sessionSaved {
                    // XP Summary
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.success)

                        Text("Session Saved!")
                            .font(.title2.bold())
                            .foregroundStyle(Theme.textPrimary)

                        Text("+\(earnedXP) XP")
                            .font(.title.bold())
                            .foregroundStyle(Theme.accent)

                        Button {
                            resetToSetup()
                        } label: {
                            Text("Done")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    // Session Complete Header
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.success)

                        Text("Session Complete")
                            .font(.title2.bold())
                            .foregroundStyle(Theme.textPrimary)

                        Text(timerService.formattedElapsedTime)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }

                    // Mood Tags
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How did this session feel?")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 8) {
                            ForEach(MoodTag.allCases, id: \.self) { mood in
                                MoodTagPill(
                                    mood: mood,
                                    isSelected: selectedMoodTags.contains(mood)
                                ) {
                                    if selectedMoodTags.contains(mood) {
                                        selectedMoodTags.remove(mood)
                                    } else {
                                        selectedMoodTags.insert(mood)
                                    }
                                }
                            }
                        }
                    }

                    // Reflection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reflection")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)

                        if !reflectionPrompt.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(Theme.streak)
                                    .font(.caption)
                                Text(reflectionPrompt)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                                    .italic()
                            }
                            .padding(10)
                            .background(Theme.cardBackgroundLight)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        TextEditor(text: $reflectionText)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(Theme.textPrimary)
                            .frame(minHeight: 100)
                            .padding(12)
                            .background(Theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Quick Actions
                    HStack(spacing: 12) {
                        Button {
                            showAddNote = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "note.text.badge.plus")
                                Text("Add Note")
                                    .font(.subheadline.bold())
                            }
                            .foregroundStyle(Theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            showAddQuote = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "quote.opening")
                                Text("Save Quote")
                                    .font(.subheadline.bold())
                            }
                            .foregroundStyle(Theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    // Save Button
                    Button {
                        saveSession()
                    } label: {
                        Text("Save Session")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showAddNote) {
            if let book = selectedBook {
                AddNoteView(preselectedBook: book)
            }
        }
        .sheet(isPresented: $showAddQuote) {
            if let book = selectedBook {
                AddQuoteView(preselectedBook: book)
            }
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
        reflectionPrompt = Prompts.reflections.randomElement() ?? ""
        withAnimation { phase = .postSession }
    }

    // MARK: - Save Logic

    private func saveSession() {
        guard let book = selectedBook else { return }
        let elapsed = timerService.elapsedSeconds

        // Calculate XP
        var xp = XPValues.sessionCompletion
        if !selectedMoodTags.isEmpty { xp += XPValues.moodTagsSelected }
        if !reflectionText.trimmingCharacters(in: .whitespaces).isEmpty {
            xp += XPValues.journalReflection
        }
        xp = min(xp, XPValues.maxPerSession)

        let session = ReadingSession(
            book: book,
            durationSeconds: elapsed,
            moodTags: selectedMoodTags.map { $0.rawValue },
            reflectionPrompt: reflectionPrompt.isEmpty ? nil : reflectionPrompt,
            reflectionText: reflectionText.trimmingCharacters(in: .whitespaces).isEmpty ? nil : reflectionText,
            xpEarned: xp
        )
        session.supabaseUserId = authService.currentUserId
        modelContext.insert(session)
        savedSession = session

        // Update UserStats
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

        earnedXP = xp
        withAnimation { sessionSaved = true }
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
        selectedMoodTags = []
        reflectionPrompt = ""
        reflectionText = ""
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
        .preferredColorScheme(.dark)
}
