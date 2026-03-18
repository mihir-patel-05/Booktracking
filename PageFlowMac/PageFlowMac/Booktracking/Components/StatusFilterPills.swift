import SwiftUI

struct StatusFilterPills: View {
    @Binding var selected: BookStatus?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(label: "All", icon: "books.vertical", isSelected: selected == nil) {
                    selected = nil
                }
                ForEach(BookStatus.allCases, id: \.self) { status in
                    FilterPill(label: status.rawValue, icon: status.icon, isSelected: selected == status) {
                        selected = status
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct FilterPill: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Theme.accent : Theme.cardBackground)
            .foregroundStyle(isSelected ? .white : Theme.textSecondary)
            .clipShape(Capsule())
        }
    }
}
