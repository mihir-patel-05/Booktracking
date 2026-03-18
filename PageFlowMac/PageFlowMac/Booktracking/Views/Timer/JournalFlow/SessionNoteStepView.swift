import SwiftUI

struct SessionNoteStepView: View {
    @Binding var noteTitle: String
    @Binding var noteContent: String
    @Binding var noteChapterRef: String
    let notePrompt: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Prompt inspiration
                if !notePrompt.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(Theme.streak)
                            .font(.caption)
                        Text(notePrompt)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .italic()
                    }
                    .padding(10)
                    .background(Theme.cardBackgroundLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)

                    TextField("Note title", text: $noteTitle)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(12)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)

                    TextEditor(text: $noteContent)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(Theme.textPrimary)
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Chapter Reference (optional)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Chapter Reference")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)

                    TextField("e.g. Chapter 3", text: $noteChapterRef)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(12)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }
}
