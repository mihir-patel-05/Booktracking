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

struct MacContentView: View {
    @State private var selectedItem: SidebarItem? = .home

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .listStyle(.sidebar)
            .navigationTitle("PageFlow")
        } detail: {
            Group {
                switch selectedItem {
                case .home:
                    NavigationStack {
                        HomeView()
                    }
                case .timer:
                    NavigationStack {
                        TimerView()
                    }
                case .notes:
                    NavigationStack {
                        NotesView()
                    }
                case .quotes:
                    NavigationStack {
                        QuotesView()
                    }
                case .stats:
                    NavigationStack {
                        StatsView()
                    }
                case nil:
                    Text("Select an item from the sidebar")
                        .font(.title3)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }
}
