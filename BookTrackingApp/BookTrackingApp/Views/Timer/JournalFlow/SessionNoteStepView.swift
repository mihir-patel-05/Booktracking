import SwiftUI

struct SessionNoteStepView: View {
    @Binding var noteTitle: String
    @Binding var noteContent: String
    @Binding var noteChapterRef: String
    let notePrompt: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if !notePrompt.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(Theme.streak)
                            .font(.system(size: 13))
                            .padding(.top, 2)
                        Text(notePrompt)
                            .font(.dmSans(13))
                            .italic()
                            .foregroundStyle(Theme.textSecondary)
                            .lineSpacing(2)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .designCard(cornerRadius: 12)
                }

                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel("Title", bottomPadding: 0)
                    TextField("Note title", text: $noteTitle)
                        .font(.dmSans(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .tint(Theme.accentLight)
                        .padding(14)
                        .designCard(cornerRadius: 14)
                }

                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel("Content", bottomPadding: 0)
                    TextEditor(text: $noteContent)
                        .scrollContentBackground(.hidden)
                        .font(.dmSans(14))
                        .foregroundStyle(Theme.textPrimary)
                        .tint(Theme.accentLight)
                        .frame(minHeight: 130)
                        .padding(10)
                        .designCard(cornerRadius: 14)
                }

                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel("Chapter Reference (Optional)", bottomPadding: 0)
                    TextField("e.g. Chapter 3", text: $noteChapterRef)
                        .font(.dmSans(14))
                        .foregroundStyle(Theme.textPrimary)
                        .tint(Theme.accentLight)
                        .padding(14)
                        .designCard(cornerRadius: 14)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}
