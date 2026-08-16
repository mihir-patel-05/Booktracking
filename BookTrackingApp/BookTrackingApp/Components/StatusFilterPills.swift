import SwiftUI

struct StatusFilterPills: View {
    @Binding var selected: BookStatus?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                FilterPill(label: "All", isSelected: selected == nil) {
                    selected = nil
                }
                ForEach(BookStatus.allCases, id: \.self) { status in
                    FilterPill(label: status.rawValue, isSelected: selected == status) {
                        selected = status
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct FilterPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.dmSans(12, weight: isSelected ? .semibold : .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Theme.accent : Theme.cardBackground)
                .foregroundStyle(isSelected ? .white : Theme.textSecondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
