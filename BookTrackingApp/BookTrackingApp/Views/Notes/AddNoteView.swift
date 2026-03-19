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
                    VStack(alignment: .leading, spacing: 20) {
                        // Book Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Book")
                                .font(.subheadline.bold())
                                .foregroundStyle(Theme.textSecondary)

                            Button {
                                showBookPicker = true
                            } label: {
                                HStack {
                                    Text(selectedBook?.title ?? "Select a book")
                                        .foregroundStyle(selectedBook != nil ? Theme.textPrimary : Theme.textMuted)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(Theme.textMuted)
                                }
                                .padding(12)
                                .background(Theme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        // Prompt Inspiration
                        if !promptInspiration.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(Theme.streak)
                                    .font(.caption)
                                Text(promptInspiration)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                                    .italic()
                            }
                            .padding(12)
                            .background(Theme.cardBackgroundLight)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.subheadline.bold())
                                .foregroundStyle(Theme.textSecondary)

                            TextField("Note title", text: $title)
                                .foregroundStyle(Theme.textPrimary)
                                .padding(12)
                                .background(Theme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Content
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Content")
                                .font(.subheadline.bold())
                                .foregroundStyle(Theme.textSecondary)

                            TextEditor(text: $content)
                                .scrollContentBackground(.hidden)
                                .foregroundStyle(Theme.textPrimary)
                                .frame(minHeight: 150)
                                .padding(12)
                                .background(Theme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Chapter Reference (Optional)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Chapter Reference (Optional)")
                                .font(.subheadline.bold())
                                .foregroundStyle(Theme.textSecondary)

                            TextField("e.g. Chapter 3", text: $chapterReference)
                                .foregroundStyle(Theme.textPrimary)
                                .padding(12)
                                .background(Theme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
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
                        .foregroundStyle(Theme.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveNote() }
                        .foregroundStyle(Theme.accent)
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
