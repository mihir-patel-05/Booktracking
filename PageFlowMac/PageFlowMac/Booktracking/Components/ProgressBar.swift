import SwiftUI

struct ProgressBar: View {
    let progress: Double
    var height: CGFloat = 6
    var backgroundColor: Color = Theme.cardBackgroundLight
    var foregroundColor: Color = Theme.accent

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(backgroundColor)

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(foregroundColor)
                    .frame(width: max(0, geo.size.width * min(CGFloat(progress), 1.0)))
            }
        }
        .frame(height: height)
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressBar(progress: 0.3)
        ProgressBar(progress: 0.7, foregroundColor: Theme.success)
        ProgressBar(progress: 1.0)
    }
    .padding()
    .background(Theme.background)
}
