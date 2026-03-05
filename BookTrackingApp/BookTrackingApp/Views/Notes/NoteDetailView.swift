import SwiftUI
import SwiftData

struct NoteDetailView: View {
    @Bindable var note: SessionNote

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Book Info
                    if let book = note.book {
                        HStack(spacing: 8) {
                            Image(systemName: "book.fill")
                                .foregroundStyle(Theme.accent)
                            Text(book.title)
                                .font(.subheadline.bold())
                                .foregroundStyle(Theme.accentLight)
                        }
                        .padding(12)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.subheadline.bold())
                            .foregroundStyle(Theme.textSecondary)

                        TextField("Note title", text: $note.title)
                            .foregroundStyle(Theme.textPrimary)
                            .padding(12)
                            .background(Theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onChange(of: note.title) {
                                note.needsSync = true
                            }
                    }

                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content")
                            .font(.subheadline.bold())
                            .foregroundStyle(Theme.textSecondary)

                        TextEditor(text: $note.content)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(Theme.textPrimary)
                            .frame(minHeight: 200)
                            .padding(12)
                            .background(Theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onChange(of: note.content) {
                                note.needsSync = true
                            }
                    }

                    // Chapter Reference
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Chapter Reference")
                            .font(.subheadline.bold())
                            .foregroundStyle(Theme.textSecondary)

                        TextField("e.g. Chapter 3", text: Binding(
                            get: { note.chapterReference ?? "" },
                            set: {
                                note.chapterReference = $0.isEmpty ? nil : $0
                                note.needsSync = true
                            }
                        ))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(12)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Date
                    HStack {
                        Spacer()
                        Text("Created \(note.dateCreated.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
