import SwiftUI
import SwiftData

struct NoteDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var note: SessionNote
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let book = note.book {
                        bookCard(book: book)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Title", bottomPadding: 0)
                        TextField("Note title", text: $note.title)
                            .font(.dmSans(15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.accentLight)
                            .padding(14)
                            .designCard(cornerRadius: 14)
                            .onChange(of: note.title) { note.needsSync = true }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Content", bottomPadding: 0)
                        TextEditor(text: $note.content)
                            .scrollContentBackground(.hidden)
                            .font(.dmSans(14))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.accentLight)
                            .frame(minHeight: 200)
                            .padding(10)
                            .designCard(cornerRadius: 14)
                            .onChange(of: note.content) { note.needsSync = true }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Chapter Reference", bottomPadding: 0)
                        TextField("e.g. Chapter 3", text: Binding(
                            get: { note.chapterReference ?? "" },
                            set: {
                                note.chapterReference = $0.isEmpty ? nil : $0
                                note.needsSync = true
                            }
                        ))
                        .font(.dmSans(14))
                        .foregroundStyle(Theme.textPrimary)
                        .tint(Theme.accentLight)
                        .padding(14)
                        .designCard(cornerRadius: 14)
                    }

                    HStack {
                        Spacer()
                        Text("Created \(note.dateCreated.formatted(date: .abbreviated, time: .shortened))")
                            .font(.dmSans(11))
                            .foregroundStyle(Theme.textMuted)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Note")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog("Delete this note?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Note", role: .destructive) {
                modelContext.delete(note)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the note from your saved notes.")
        }
    }

    private func bookCard(book: Book) -> some View {
        HStack(spacing: 12) {
            BookCoverView(book: book, size: .sm)
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.dmSans(14, weight: .semibold))
                    .foregroundStyle(Theme.accentLight)
                    .lineLimit(1)
                Text(book.author)
                    .font(.dmSans(11))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(12)
        .designCard(cornerRadius: 14)
    }
}
