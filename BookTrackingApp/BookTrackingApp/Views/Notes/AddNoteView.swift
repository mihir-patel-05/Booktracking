import SwiftUI
import SwiftData

struct AddNoteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService

    @State private var title = ""
    @State private var content = ""
    @State private var chapterReference = ""
    @State private var selectedBook: Book?
    @State private var showBookPicker = false
    @State private var promptInspiration: String

    var preselectedBook: Book?

    init(preselectedBook: Book? = nil) {
        self.preselectedBook = preselectedBook
        _promptInspiration = State(initialValue: Prompts.notes.randomElement() ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        bookPickerCard
                        if !promptInspiration.isEmpty { promptCard }
                        titleField
                        contentField
                        chapterField
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Note")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.accentLight)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveNote() }
                        .foregroundStyle(Theme.accentLight)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || selectedBook == nil)
                }
            }
            .sheet(isPresented: $showBookPicker) {
                BookPickerSheet(filterStatus: nil) { book in
                    selectedBook = book
                }
            }
            .onAppear {
                if let preselectedBook {
                    selectedBook = preselectedBook
                }
            }
        }
    }

    private var bookPickerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel("Book", bottomPadding: 0)
            Button { showBookPicker = true } label: {
                HStack(spacing: 12) {
                    if let book = selectedBook {
                        BookCoverView(book: book, size: .sm)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(book.title)
                                .font(.dmSans(14, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(1)
                            Text(book.author)
                                .font(.dmSans(11))
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text("Select a book")
                            .font(.dmSans(14))
                            .foregroundStyle(Theme.textMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(14)
                .designCard(cornerRadius: 14)
            }
            .buttonStyle(.plain)
        }
    }

    private var promptCard: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(Theme.streak)
                .font(.system(size: 13))
                .padding(.top, 2)
            Text(promptInspiration)
                .font(.dmSans(13))
                .italic()
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .designCard(cornerRadius: 12)
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel("Title", bottomPadding: 0)
            TextField("Note title", text: $title)
                .font(.dmSans(15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .tint(Theme.accentLight)
                .padding(14)
                .designCard(cornerRadius: 14)
        }
    }

    private var contentField: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel("Content", bottomPadding: 0)
            TextEditor(text: $content)
                .scrollContentBackground(.hidden)
                .font(.dmSans(14))
                .foregroundStyle(Theme.textPrimary)
                .tint(Theme.accentLight)
                .frame(minHeight: 160)
                .padding(10)
                .designCard(cornerRadius: 14)
        }
    }

    private var chapterField: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel("Chapter Reference (Optional)", bottomPadding: 0)
            TextField("e.g. Chapter 3", text: $chapterReference)
                .font(.dmSans(14))
                .foregroundStyle(Theme.textPrimary)
                .tint(Theme.accentLight)
                .padding(14)
                .designCard(cornerRadius: 14)
        }
    }

    private func saveNote() {
        guard let book = selectedBook else { return }
        let note = SessionNote(
            book: book,
            title: title.trimmingCharacters(in: .whitespaces),
            content: content.trimmingCharacters(in: .whitespaces),
            chapterReference: chapterReference.trimmingCharacters(in: .whitespaces).isEmpty ? nil : chapterReference.trimmingCharacters(in: .whitespaces)
        )
        note.supabaseUserId = authService.currentUserId
        modelContext.insert(note)
        dismiss()
    }
}
