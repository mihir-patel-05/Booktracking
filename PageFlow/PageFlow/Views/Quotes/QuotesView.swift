import SwiftUI

struct QuotesView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.accent)

                    Text("Quotes")
                        .font(.title2.bold())
                        .foregroundStyle(Theme.textPrimary)

                    Text("Your saved quotes will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .navigationTitle("Quotes")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    QuotesView()
        .preferredColorScheme(.dark)
}
