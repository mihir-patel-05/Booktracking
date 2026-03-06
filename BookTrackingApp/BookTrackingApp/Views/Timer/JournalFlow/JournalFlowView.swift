import SwiftUI
import SwiftData

struct JournalFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthService.self) private var authService

    let book: Book
    let timerService: TimerService
    let onSave: (ReadingSession, Int) -> Void

    // Step navigation
    @State private var currentStep = 0

    // Step 1: Mood & Reflection
    @State private var selectedMoodTags: Set<MoodTag> = []
    @State private var reflectionText = ""
    let reflectionPrompt: String

    // Step 2: Session Note
    @State private var noteTitle = ""
    @State private var noteContent = ""
    @State private var noteChapterRef = ""
    let notePrompt: String

    // Step 3: Quote
    @State private var quoteText = ""

    init(book: Book, timerService: TimerService, onSave: @escaping (ReadingSession, Int) -> Void) {
        self.book = book
        self.timerService = timerService
        self.onSave = onSave
        self.reflectionPrompt = Prompts.reflections.randomElement() ?? ""
        self.notePrompt = Prompts.notes.randomElement() ?? ""
    }

    private var xpBreakdown: XPBreakdown {
        XPService.calculate(
            hasMoods: !selectedMoodTags.isEmpty,
            hasReflection: !reflectionText.trimmingCharacters(in: .whitespaces).isEmpty,
            hasNote: !noteTitle.trimmingCharacters(in: .whitespaces).isEmpty,
            hasQuote: !quoteText.trimmingCharacters(in: .whitespaces).isEmpty
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.success)

                Text("Session Complete")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.textPrimary)

                Text(timerService.formattedElapsedTime)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.top, 8)
            .padding(.bottom, 12)

            // Step indicator
            JournalStepIndicator(currentStep: currentStep)
                .padding(.bottom, 16)

            // Step content
            Group {
                switch currentStep {
                case 0:
                    MoodReflectionStepView(
                        selectedMoodTags: $selectedMoodTags,
                        reflectionText: $reflectionText,
                        reflectionPrompt: reflectionPrompt
                    )
                case 1:
                    SessionNoteStepView(
                        noteTitle: $noteTitle,
                        noteContent: $noteContent,
                        noteChapterRef: $noteChapterRef,
                        notePrompt: notePrompt
                    )
                case 2:
                    QuoteSaveStepView(
                        quoteText: $quoteText,
                        book: book,
                        elapsedTime: timerService.formattedElapsedTime,
                        xpBreakdown: xpBreakdown
                    )
                default:
                    EmptyView()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            // Bottom navigation bar
            bottomBar
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            // Back button
            if currentStep > 0 {
                Button {
                    withAnimation { currentStep -= 1 }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                }
            }

            Spacer()

            if currentStep < 2 {
                // Skip button
                Button {
                    withAnimation { currentStep += 1 }
                } label: {
                    Text("Skip")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(.trailing, 12)

                // Next button
                Button {
                    withAnimation { currentStep += 1 }
                } label: {
                    HStack(spacing: 4) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Theme.accent)
                    .clipShape(Capsule())
                }
            } else {
                // Save button (Step 3)
                Button {
                    saveSession()
                } label: {
                    Text("Save Session")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Theme.accent)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Theme.background)
    }

    // MARK: - Save

    private func saveSession() {
        let elapsed = timerService.elapsedSeconds
        let breakdown = xpBreakdown

        // Create ReadingSession
        let session = ReadingSession(
            book: book,
            durationSeconds: elapsed,
            moodTags: selectedMoodTags.map { $0.rawValue },
            reflectionPrompt: reflectionPrompt.isEmpty ? nil : reflectionPrompt,
            reflectionText: reflectionText.trimmingCharacters(in: .whitespaces).isEmpty ? nil : reflectionText,
            xpEarned: breakdown.total
        )
        session.supabaseUserId = authService.currentUserId
        modelContext.insert(session)

        // Create SessionNote if filled
        let trimmedTitle = noteTitle.trimmingCharacters(in: .whitespaces)
        if !trimmedTitle.isEmpty {
            let note = SessionNote(
                book: book,
                session: session,
                title: trimmedTitle,
                content: noteContent,
                chapterReference: noteChapterRef.trimmingCharacters(in: .whitespaces).isEmpty ? nil : noteChapterRef
            )
            note.supabaseUserId = authService.currentUserId
            modelContext.insert(note)
        }

        // Create Quote if filled
        let trimmedQuote = quoteText.trimmingCharacters(in: .whitespaces)
        if !trimmedQuote.isEmpty {
            let quote = Quote(
                book: book,
                session: session,
                text: trimmedQuote
            )
            quote.supabaseUserId = authService.currentUserId
            modelContext.insert(quote)
        }

        onSave(session, breakdown.total)
    }
}
