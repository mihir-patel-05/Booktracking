import SwiftUI

struct MoodReflectionStepView: View {
    @Binding var selectedMoodTags: Set<MoodTag>
    @Binding var reflectionText: String
    let reflectionPrompt: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Mood Tags
                VStack(alignment: .leading, spacing: 12) {
                    Text("How did this session feel?")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 8) {
                        ForEach(MoodTag.allCases, id: \.self) { mood in
                            MoodTagPill(
                                mood: mood,
                                isSelected: selectedMoodTags.contains(mood)
                            ) {
                                if selectedMoodTags.contains(mood) {
                                    selectedMoodTags.remove(mood)
                                } else {
                                    selectedMoodTags.insert(mood)
                                }
                            }
                        }
                    }
                }

                // Reflection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reflection")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)

                    if !reflectionPrompt.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(Theme.streak)
                                .font(.caption)
                            Text(reflectionPrompt)
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                                .italic()
                        }
                        .padding(10)
                        .background(Theme.cardBackgroundLight)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    TextEditor(text: $reflectionText)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(Theme.textPrimary)
                        .frame(minHeight: 100)
                        .padding(12)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }
}
