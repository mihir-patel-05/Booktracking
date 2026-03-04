import SwiftUI

struct StatsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.accent)

                    Text("Stats")
                        .font(.title2.bold())
                        .foregroundStyle(Theme.textPrimary)

                    Text("Your reading stats will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .navigationTitle("Stats")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    StatsView()
        .preferredColorScheme(.dark)
}
