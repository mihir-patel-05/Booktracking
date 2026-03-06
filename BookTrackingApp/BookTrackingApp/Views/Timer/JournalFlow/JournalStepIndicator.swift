import SwiftUI

struct JournalStepIndicator: View {
    let currentStep: Int
    private let steps = ["Mood", "Notes", "Save"]

    var body: some View {
        HStack(spacing: 24) {
            ForEach(0..<steps.count, id: \.self) { index in
                VStack(spacing: 6) {
                    Circle()
                        .fill(color(for: index))
                        .frame(width: 10, height: 10)

                    Text(steps[index])
                        .font(.caption2)
                        .foregroundStyle(index <= currentStep ? Theme.textSecondary : Theme.textMuted)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: currentStep)
    }

    private func color(for index: Int) -> Color {
        if index == currentStep {
            return Theme.accent
        } else if index < currentStep {
            return Theme.accentLight
        } else {
            return Theme.cardBackgroundLight
        }
    }
}
