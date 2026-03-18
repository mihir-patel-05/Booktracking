#if os(macOS)
import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case home = "Home"
    case timer = "Timer"
    case notes = "Notes"
    case quotes = "Quotes"
    case stats = "Stats"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .timer: "timer"
        case .notes: "note.text"
        case .quotes: "quote.opening"
        case .stats: "chart.bar.fill"
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarItem?

    var body: some View {
        List(SidebarItem.allCases, selection: $selection) { item in
            Label(item.rawValue, systemImage: item.icon)
                .tag(item)
        }
        .listStyle(.sidebar)
        .navigationTitle("PageFlow")
    }
}
#endif
