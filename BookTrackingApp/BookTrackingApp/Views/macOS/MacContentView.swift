#if os(macOS)
import SwiftUI

struct MacContentView: View {
    @State private var selectedItem: SidebarItem? = .home

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedItem)
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
        .frame(minWidth: 800, minHeight: 600)
    }
}
#endif
