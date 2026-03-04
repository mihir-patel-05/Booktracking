import SwiftUI
import SwiftData

@main
struct PageFlowApp: App {
    @State private var authService = AuthService()
    @State private var syncService = SyncService()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Book.self,
            ReadingSession.self,
            SessionNote.self,
            Quote.self,
            UserStats.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authService)
                .environment(syncService)
        }
        .modelContainer(sharedModelContainer)
    }
}
