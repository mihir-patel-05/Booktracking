import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) private var authService

    var body: some View {
        Group {
            if authService.isLoading {
                loadingView
            } else if authService.isAuthenticated {
                mainTabView
            } else {
                AuthView()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var loadingView: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ProgressView()
                .tint(Theme.accent)
        }
    }

    private var mainTabView: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            TimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

            NotesView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }

            QuotesView()
                .tabItem {
                    Label("Quotes", systemImage: "quote.opening")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    ContentView()
        .environment(AuthService())
}
