import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.accent)

                    Text("Home")
                        .font(.title2.bold())
                        .foregroundStyle(Theme.textPrimary)

                    Text("Your reading dashboard will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .navigationTitle("PageFlow")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
}
