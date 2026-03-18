import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AuthService.self) private var authService
    @Environment(SyncService.self) private var syncService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if authService.isLoading {
                loadingView
            } else if authService.isAuthenticated {
                MacContentView()
            } else {
                AuthView()
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive, let userId = authService.currentUserId {
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
}
