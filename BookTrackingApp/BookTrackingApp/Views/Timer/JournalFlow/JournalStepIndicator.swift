import SwiftUI

struct JournalStepIndicator: View {
    let currentStep: Int
    private let steps = ["Mood", "Notes", "Quote"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { index in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(for: index))
                        .frame(height: 3)

                    Text(steps[index].uppercased())
                        .font(.dmSans(9, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(textColor(for: index))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: currentStep)
        .padding(.horizontal, 20)
    }

    private func barColor(for index: Int) -> Color {
        if index < currentStep { return Theme.accent }
        if index == currentStep { return Theme.accentLight }
        return Theme.cardBackgroundLight
    }

    private func textColor(for index: Int) -> Color {
        if index == currentStep { return Theme.accentLight }
        if index < currentStep { return Theme.textSecondary }
        return Theme.textMuted
    }
}
