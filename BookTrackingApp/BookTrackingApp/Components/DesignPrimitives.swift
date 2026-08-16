import SwiftUI

// MARK: - SectionLabel

struct SectionLabel: View {
    let text: String
    var bottomPadding: CGFloat = 10

    init(_ text: String, bottomPadding: CGFloat = 10) {
        self.text = text
        self.bottomPadding = bottomPadding
    }

    var body: some View {
        Text(text.uppercased())
            .font(.dmSans(10, weight: .semibold))
            .tracking(1.0)
            .foregroundStyle(Theme.textMuted)
            .padding(.bottom, bottomPadding)
    }
}

// MARK: - Chip

struct Chip: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.dmSans(11, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 2)
            .background(color.opacity(0.10))
            .clipShape(Capsule())
    }
}

// MARK: - ProgressBarV2

struct ProgressBarV2: View {
    let value: Double  // 0...1 or 0...100 (auto-detected)
    var color: Color = Theme.accent
    var height: CGFloat = 5

    private var clamped: Double {
        let v = value > 1 ? value / 100 : value
        return max(0, min(1, v))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.07))
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * clamped)
            }
        }
        .frame(height: height)
    }
}

// MARK: - BookCoverView

enum CoverSize {
    case sm, md, lg, xl

    var width: CGFloat {
        switch self {
        case .sm: return 42
        case .md: return 70
        case .lg: return 90
        case .xl: return 140
        }
    }
    var height: CGFloat {
        switch self {
        case .sm: return 60
        case .md: return 100
        case .lg: return 130
        case .xl: return 200
        }
    }
    var radius: CGFloat {
        switch self {
        case .sm: return 6
        case .md: return 9
        case .lg: return 10
        case .xl: return 14
        }
    }
    var letterSize: CGFloat {
        switch self {
        case .sm: return 18
        case .md: return 24
        case .lg: return 30
        case .xl: return 46
        }
    }
}

struct BookCoverView: View {
    let title: String
    let coverURL: String?
    let paletteSeed: String
    var size: CoverSize = .md

    init(title: String, coverURL: String?, paletteSeed: String, size: CoverSize = .md) {
        self.title = title
        self.coverURL = coverURL
        self.paletteSeed = paletteSeed
        self.size = size
    }

    init(book: Book, size: CoverSize = .md) {
        self.title = book.title
        self.coverURL = book.coverURL
        self.paletteSeed = book.id.uuidString
        self.size = size
    }

    var body: some View {
        Group {
            if let urlString = coverURL,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        gradientPlaceholder
                    @unknown default:
                        gradientPlaceholder
                    }
                }
            } else {
                gradientPlaceholder
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: size.radius))
        .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
    }

    private var gradientPlaceholder: some View {
        let palette = Theme.coverPalette(seed: paletteSeed)
        return LinearGradient(
            colors: [palette.0, palette.1],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Text(String(title.first ?? "?"))
                .font(.playfair(size.letterSize, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.85))
        )
    }
}

// MARK: - Card modifier

struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = 14
    var background: Color = Theme.cardBackground
    var borderColor: Color = Theme.border

    func body(content: Content) -> some View {
        content
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
}

extension View {
    func designCard(cornerRadius: CGFloat = 14,
                    background: Color = Theme.cardBackground,
                    borderColor: Color = Theme.border) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius, background: background, borderColor: borderColor))
    }

    func bannerCard(cornerRadius: CGFloat = 18) -> some View {
        self
            .background(Theme.bannerGradient)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Theme.borderStrong, lineWidth: 1)
            )
    }
}

// MARK: - PrimaryButtonStyle

struct PrimaryGradientButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.dmSans(16, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(
                Group {
                    if enabled {
                        Theme.primaryButtonGradient
                    } else {
                        Theme.cardBackgroundLight
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: enabled ? Theme.accent.opacity(0.45) : .clear, radius: 14, y: 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
