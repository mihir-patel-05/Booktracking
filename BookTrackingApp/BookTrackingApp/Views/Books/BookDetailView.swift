import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var book: Book

    @Environment(AuthService.self) private var authService

    @State private var pageInput = ""
    @State private var showDeleteConfirmation = false
    @State private var showAddNote = false
    @State private var showAddQuote = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    coverSection
                    infoSection
                    progressSection
                    statusSection
                    sessionsSection
                    notesSection
                    quotesSection
                    deleteSection
                }
                .padding()
            }
        }
        .navigationTitle(book.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        #endif
        .alert("Delete Book?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(book)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \"\(book.title)\" and all associated sessions, notes, and quotes.")
        }
        .sheet(isPresented: $showAddNote) {
            AddNoteView(preselectedBook: book)
        }
        .sheet(isPresented: $showAddQuote) {
            AddQuoteView(preselectedBook: book)
        }
        .onAppear {
            pageInput = String(book.currentPage)
        }
    }

    private var coverSection: some View {
        HStack {
            Spacer()
            Group {
                if let urlString = book.coverURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fit)
                        default:
                            coverPlaceholder
                        }
                    }
                } else {
                    coverPlaceholder
                }
            }
            .frame(width: 120, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: Theme.accent.opacity(0.3), radius: 10)
            Spacer()
        }
    }

    private var coverPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Theme.cardBackgroundLight)
            .overlay(
                Image(systemName: "book.closed.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Theme.textMuted)
            )
    }

    private var infoSection: some View {
        VStack(spacing: 8) {
            Text(book.title)
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Text(book.author)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            Text("\(book.totalPages) pages")
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            ProgressBar(progress: book.progressPercentage, height: 8)

            Text("\(Int(book.progressPercentage * 100))% complete")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 12) {
                TextField("Page", text: $pageInput)
                    .keyboardType(.numberPad)
                    .padding(10)
                    .background(Theme.cardBackground)
                    .foregroundStyle(Theme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(width: 100)

                Text("of \(book.totalPages)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)

                Spacer()

                Button("Update") {
                    updateProgress()
                }
                .font(.subheadline.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.accent)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            Picker("Status", selection: Binding(
                get: { book.status },
                set: { newStatus in
                    book.status = newStatus
                    book.needsSync = true
                    if newStatus == .completed && book.dateCompleted == nil {
                        book.dateCompleted = Date()
                    }
                    if newStatus != .completed {
                        book.dateCompleted = nil
                    }
                }
            )) {
                ForEach(BookStatus.allCases, id: \.self) { status in
                    Label(status.rawValue, systemImage: status.icon)
                        .tag(status)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Sessions Section

    private var sessionsSection: some View {
        let sortedSessions = book.sessions.sorted { $0.startDate > $1.startDate }
        let totalMinutes = book.sessions.reduce(0) { $0 + $1.durationSeconds } / 60

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Reading Sessions")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(book.sessions.count)")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.textMuted)
            }

            if book.sessions.isEmpty {
                Text("No sessions yet. Start a reading timer!")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                Text("Total: \(totalMinutes) min")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)

                ForEach(Array(sortedSessions.prefix(3))) { session in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.startDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(session.durationSeconds / 60) min")
                                .font(.caption2)
                                .foregroundStyle(Theme.textMuted)
                        }
                        Spacer()
                        HStack(spacing: 2) {
                            ForEach(session.moodTags, id: \.self) { tagString in
                                if let mood = MoodTag(rawValue: tagString) {
                                    Text(mood.emoji)
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .padding(8)
                    .background(Theme.cardBackgroundLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        let sortedNotes = book.notes.sorted { $0.dateCreated > $1.dateCreated }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notes")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button {
                    showAddNote = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Theme.accent)
                }
            }

            if book.notes.isEmpty {
                Text("No notes yet.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                ForEach(Array(sortedNotes.prefix(3))) { note in
                    NavigationLink {
                        NoteDetailView(note: note)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.title)
                                .font(.caption.bold())
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(1)
                            Text(note.content)
                                .font(.caption2)
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(2)
                            Text(note.dateCreated.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(Theme.textMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Theme.cardBackgroundLight)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Quotes Section

    private var quotesSection: some View {
        let sortedQuotes = book.quotes.sorted { $0.dateCreated > $1.dateCreated }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quotes")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button {
                    showAddQuote = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Theme.accent)
                }
            }

            if book.quotes.isEmpty {
                Text("No quotes saved yet.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                ForEach(Array(sortedQuotes.prefix(3))) { quote in
                    QuoteCard(quote: quote)
                }
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var deleteSection: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Book")
            }
            .font(.subheadline.bold())
            .frame(maxWidth: .infinity)
            .padding()
            .background(Theme.error.opacity(0.15))
            .foregroundStyle(Theme.error)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func updateProgress() {
        guard let newPage = Int(pageInput) else { return }
        let clamped = min(max(0, newPage), book.totalPages)
        book.currentPage = clamped
        book.needsSync = true
        pageInput = String(clamped)

        if clamped == book.totalPages && book.status != .completed {
            book.status = .completed
            book.dateCompleted = Date()
        }
    }
}
