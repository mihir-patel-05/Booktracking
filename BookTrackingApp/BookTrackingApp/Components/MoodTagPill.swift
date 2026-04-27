import SwiftUI

struct MoodTagPill: View {
    let mood: MoodTag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(mood.emoji)
                    .font(.system(size: 13))
                Text(mood.rawValue)
                    .font(.dmSans(13, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? mood.color.opacity(0.10) : Theme.cardBackground)
            .foregroundStyle(isSelected ? mood.color : Theme.textSecondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? mood.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
