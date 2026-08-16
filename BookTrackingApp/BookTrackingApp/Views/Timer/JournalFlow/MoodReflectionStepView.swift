import SwiftUI

struct MoodReflectionStepView: View {
    @Binding var selectedMoodTags: Set<MoodTag>
    @Binding var reflectionText: String
    let reflectionPrompt: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 0) {
                    SectionLabel("Reading Vibe")
                    FlowLayout(spacing: 8) {
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

                VStack(alignment: .leading, spacing: 0) {
                    SectionLabel("Reflection")
                    VStack(alignment: .leading, spacing: 10) {
                        if !reflectionPrompt.isEmpty {
                            Text("\u{201C}\(reflectionPrompt)\u{201D}")
                                .font(.dmSans(13))
                                .italic()
                                .foregroundStyle(Theme.accentLight)
                                .lineSpacing(3)
                        }
                        TextEditor(text: $reflectionText)
                            .scrollContentBackground(.hidden)
                            .font(.dmSans(14))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.accentLight)
                            .frame(minHeight: 90)
                    }
                    .padding(14)
                    .designCard(cornerRadius: 14)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

/// Simple flow layout that wraps children to next line when they overflow.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let arrangement = arrange(subviews: subviews, in: width)
        return arrangement.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(subviews: subviews, in: bounds.width)
        for (index, point) in arrangement.points.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func arrange(subviews: Subviews, in width: CGFloat) -> (size: CGSize, points: [CGPoint]) {
        var points: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxRowWidth = max(maxRowWidth, x)
        }

        return (CGSize(width: maxRowWidth, height: y + rowHeight), points)
    }
}
