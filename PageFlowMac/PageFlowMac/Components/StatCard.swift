import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var iconColor: Color = Theme.accent

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Theme.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
