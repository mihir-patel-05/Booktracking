import SwiftUI
import SwiftData

struct JournalFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthService.self) private var authService

    let book: Book
    let timerService: TimerService
    let onSave: (ReadingSession, Int) -> Void

    @State private var currentStep = 0

    @State private var selectedMoodTags: Set<MoodTag> = []
    @State private var reflectionText = ""
    let reflectionPrompt: String

    @State private var noteTitle = ""
    @State private var noteContent = ""
    @State private var noteChapterRef = ""
    let notePrompt: String

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
            VStack(spacing: 6) {
                Text("✨").font(.system(size: 40))
                Text("Session Complete!")
                    .font(.playfair(22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(book.title) · \(timerService.formattedElapsedTime)")
                    .font(.dmSans(13))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            .padding(.top, 14)
            .padding(.bottom, 14)
            .padding(.horizontal, 20)

            JournalStepIndicator(currentStep: currentStep)
                .padding(.bottom, 12)

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

            bottomBar
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if currentStep > 0 {
                Button {
                    withAnimation { currentStep -= 1 }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Back")
                    }
                    .font(.dmSans(13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if currentStep < 2 {
                Button {
                    withAnimation { currentStep += 1 }
                } label: {
                    Text("Skip")
                        .font(.dmSans(13))
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation { currentStep += 1 }
                } label: {
                    HStack(spacing: 6) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .font(.dmSans(14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(Theme.primaryButtonGradient)
                    .clipShape(Capsule())
                    .shadow(color: Theme.accent.opacity(0.4), radius: 10, y: 4)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    saveSession()
                } label: {
                    Text("Save Session →")
                        .font(.dmSans(14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 11)
                        .background(Theme.primaryButtonGradient)
                        .clipShape(Capsule())
                        .shadow(color: Theme.accent.opacity(0.45), radius: 10, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Theme.background)
    }

    private func saveSession() {
        let elapsed = timerService.elapsedSeconds
        let breakdown = xpBreakdown

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
