import SwiftUI

struct TimerView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "timer")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.accent)

                    Text("Timer")
                        .font(.title2.bold())
                        .foregroundStyle(Theme.textPrimary)

                    Text("Start a reading session here.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .navigationTitle("Timer")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    TimerView()
        .preferredColorScheme(.dark)
}
