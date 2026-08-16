import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @Environment(AuthService.self) private var authService
    @Environment(SyncService.self) private var syncService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if canImport(UIKit)
        configureTabBarAppearance()
        configureNavigationBarAppearance()
        #endif
    }

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
        .onChange(of: scenePhase) { _, newPhase in
            #if os(macOS)
            let shouldSync = newPhase == .inactive
            #else
            let shouldSync = newPhase == .background
            #endif
            if shouldSync, let userId = authService.currentUserId {
                Task {
                    await syncService.syncAll(modelContext: modelContext, userId: userId)
                }
            }
        }
    }

    private var loadingView: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ProgressView()
                .tint(Theme.accent)
        }
    }

    private var mainTabView: some View {
        #if os(macOS)
        MacContentView()
        #else
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
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
                    Label("Stats", systemImage: "chart.bar")
                }
        }
        .tint(Theme.accentLight)
        #endif
    }

    #if canImport(UIKit)
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.cardBackground)
        appearance.shadowColor = UIColor(Theme.border)

        let mutedColor = UIColor(Theme.textMuted)
        let selectedColor = UIColor(Theme.accentLight)

        let labelFont = UIFont(name: "DMSans-Regular", size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .semibold)
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .kern: 0.5,
        ]

        for itemAppearance in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
            itemAppearance.normal.iconColor = mutedColor
            itemAppearance.selected.iconColor = selectedColor
            itemAppearance.normal.titleTextAttributes = labelAttributes.merging([.foregroundColor: mutedColor]) { _, new in new }
            itemAppearance.selected.titleTextAttributes = labelAttributes.merging([.foregroundColor: selectedColor]) { _, new in new }
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.background)
        appearance.shadowColor = .clear

        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.textPrimary),
            .font: UIFont(name: "DMSans-Regular", size: 17) ?? UIFont.systemFont(ofSize: 17, weight: .semibold),
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Theme.textPrimary),
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    #endif
}

#Preview {
    ContentView()
        .environment(AuthService())
        .environment(SyncService())
}
