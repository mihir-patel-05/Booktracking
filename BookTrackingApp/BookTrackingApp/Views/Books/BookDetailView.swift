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
    @State private var section: DetailSection = .sessions

    enum DetailSection: String, CaseIterable {
        case sessions = "Sessions"
        case notes = "Notes"
        case quotes = "Quotes"
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    coverHero
                    titleBlock
                    progressCard
                    statusCard
                    sectionPicker
                    sectionContent
                    deleteButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        #if os(iOS)
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

    private var coverHero: some View {
        ZStack {
            // Soft gradient backdrop
            let palette = Theme.coverPalette(seed: book.id.uuidString)
            RadialGradient(
                colors: [palette.0.opacity(0.45), Color.clear],
                center: .center,
                startRadius: 20,
                endRadius: 200
            )
            .frame(height: 260)
            .blur(radius: 30)

            BookCoverView(book: book, size: .xl)
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 6) {
            Text(book.title)
                .font(.playfair(24, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text(book.author)
                .font(.dmSans(13))
                .foregroundStyle(Theme.textSecondary)
            Text("\(book.totalPages) pages")
                .font(.dmSans(11))
                .foregroundStyle(Theme.textMuted)
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel("Progress", bottomPadding: 0)
                Spacer()
                Text("\(Int(book.progressPercentage * 100))%")
                    .font(.dmSans(12, weight: .semibold))
                    .foregroundStyle(Theme.accentLight)
            }
            ProgressBarV2(value: book.progressPercentage, height: 6)

            HStack(spacing: 10) {
                TextField("Page", text: $pageInput)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                    .font(.dmSans(14))
                    .foregroundStyle(Theme.textPrimary)
                    .tint(Theme.accentLight)
                    .padding(10)
                    .background(Theme.cardBackgroundLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(width: 90)

                Text("of \(book.totalPages)")
                    .font(.dmSans(13))
                    .foregroundStyle(Theme.textSecondary)

                Spacer()

                Button("Update") {
                    updateProgress()
                }
                .font(.dmSans(13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(Theme.primaryButtonGradient)
                .clipShape(Capsule())
            }
        }
        .padding(16)
        .designCard(cornerRadius: 16)
    }

    private var statusCard: some View {
        let currentStatus = book.status
        return VStack(alignment: .leading, spacing: 10) {
            SectionLabel("Status", bottomPadding: 0)
            Picker("Status", selection: Binding(
                get: { currentStatus },
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
                    Text(status.rawValue).tag(status)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .designCard(cornerRadius: 16)
    }

    private var sectionPicker: some View {
        HStack(spacing: 6) {
            ForEach(DetailSection.allCases, id: \.self) { sec in
                let active = section == sec
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        section = sec
                    }
                } label: {
                    Text(sec.rawValue)
                        .font(.dmSans(13, weight: active ? .semibold : .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(active ? Theme.accent : Color.clear)
                        .foregroundStyle(active ? .white : Theme.textSecondary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.cardBackground)
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch section {
        case .sessions: sessionsList
        case .notes: notesList
        case .quotes: quotesList
        }
    }

    private var sessionsList: some View {
        let sortedSessions = book.sessions.sorted { $0.startDate > $1.startDate }
        let totalMinutes = book.sessions.reduce(0) { $0 + $1.durationSeconds } / 60

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(book.sessions.count) session\(book.sessions.count == 1 ? "" : "s")")
                    .font(.dmSans(11))
                    .foregroundStyle(Theme.textMuted)
                Spacer()
                if !book.sessions.isEmpty {
                    Text("\(totalMinutes) min total")
                        .font(.dmSans(11))
                        .foregroundStyle(Theme.accentLight)
                }
            }

            if book.sessions.isEmpty {
                emptyRow(message: "No sessions yet. Start a reading timer!")
            } else {
                ForEach(sortedSessions.prefix(8)) { session in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.startDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.dmSans(13, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(session.durationSeconds / 60) min")
                                .font(.dmSans(11))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            ForEach(session.moodTags.prefix(3), id: \.self) { tag in
                                if let mood = MoodTag(rawValue: tag) {
                                    Circle()
                                        .fill(mood.color)
                                        .frame(width: 8, height: 8)
                                        .shadow(color: mood.color.opacity(0.5), radius: 3)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .designCard(cornerRadius: 12)
                }
            }
        }
    }

    private var notesList: some View {
        let sortedNotes = book.notes.sorted { $0.dateCreated > $1.dateCreated }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(book.notes.count) note\(book.notes.count == 1 ? "" : "s")")
                    .font(.dmSans(11))
                    .foregroundStyle(Theme.textMuted)
                Spacer()
                Button { showAddNote = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Add")
                    }
                    .font(.dmSans(12, weight: .semibold))
                    .foregroundStyle(Theme.accentLight)
                }
                .buttonStyle(.plain)
            }

            if book.notes.isEmpty {
                emptyRow(message: "No notes yet.")
            } else {
                ForEach(sortedNotes.prefix(6)) { note in
                    NavigationLink {
                        NoteDetailView(note: note)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(note.title)
                                .font(.dmSans(13, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(1)
                            Text(note.content)
                                .font(.dmSans(12))
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(2)
                            Text(note.dateCreated.formatted(date: .abbreviated, time: .omitted))
                                .font(.dmSans(10))
                                .foregroundStyle(Theme.textMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .designCard(cornerRadius: 12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var quotesList: some View {
        let sortedQuotes = book.quotes.sorted { $0.dateCreated > $1.dateCreated }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(book.quotes.count) quote\(book.quotes.count == 1 ? "" : "s")")
                    .font(.dmSans(11))
                    .foregroundStyle(Theme.textMuted)
                Spacer()
                Button { showAddQuote = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Add")
                    }
                    .font(.dmSans(12, weight: .semibold))
                    .foregroundStyle(Theme.accentLight)
                }
                .buttonStyle(.plain)
            }

            if book.quotes.isEmpty {
                emptyRow(message: "No quotes saved yet.")
            } else {
                ForEach(sortedQuotes.prefix(6)) { quote in
                    QuoteCard(quote: quote)
                }
            }
        }
    }

    private func emptyRow(message: String) -> some View {
        Text(message)
            .font(.dmSans(13))
            .foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .designCard(cornerRadius: 12)
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Book")
            }
            .font(.dmSans(14, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.error.opacity(0.12))
            .foregroundStyle(Theme.error)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.error.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
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
