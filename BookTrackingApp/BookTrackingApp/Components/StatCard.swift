import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var iconColor: Color = Theme.accent
    var emoji: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let emoji {
                Text(emoji).font(.system(size: 20))
            } else {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
            }
            Text(value)
                .font(.playfair(22, weight: .bold))
                .foregroundStyle(iconColor)
            Text(title)
                .font(.dmSans(10))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .designCard(cornerRadius: 14)
    }
}
