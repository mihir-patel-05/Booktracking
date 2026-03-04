import SwiftUI

struct NotesView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "note.text")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.accent)

                    Text("Notes")
                        .font(.title2.bold())
                        .foregroundStyle(Theme.textPrimary)

                    Text("Your session notes will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .navigationTitle("Notes")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    NotesView()
        .preferredColorScheme(.dark)
}
