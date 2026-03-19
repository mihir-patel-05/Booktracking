import SwiftUI
import SwiftData

@main
struct PageFlowMacApp: App {
    @State private var authService = AuthService()
    @State private var syncService = SyncService()
    @State private var notificationService = NotificationService()
    @State private var timerService = TimerService()

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
                .environment(notificationService)
                .environment(timerService)
                .task {
                    await notificationService.requestPermission()
                }
                .frame(minWidth: 800, minHeight: 600)
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 1000, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Book...") {
                    NotificationCenter.default.post(name: .addNewBook, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("New Note...") {
                    NotificationCenter.default.post(name: .addNewNote, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])

                Button("New Quote...") {
                    NotificationCenter.default.post(name: .addNewQuote, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .option])
            }
        }

        MenuBarExtra("PageFlow Timer", systemImage: "timer") {
            MenuBarTimerView()
                .environment(timerService)
        }
        .menuBarExtraStyle(.window)
    }
}

extension Notification.Name {
    static let addNewBook = Notification.Name("addNewBook")
    static let addNewNote = Notification.Name("addNewNote")
    static let addNewQuote = Notification.Name("addNewQuote")
}
