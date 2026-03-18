import SwiftUI

struct MoodTagPill: View {
    let mood: MoodTag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.caption)
                Text(mood.rawValue)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? mood.color.opacity(0.3) : Theme.cardBackground)
            .foregroundStyle(isSelected ? mood.color : Theme.textSecondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? mood.color : Color.clear, lineWidth: 1)
            )
        }
    }
}
