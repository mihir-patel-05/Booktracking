import SwiftUI

enum Theme {
    // MARK: - Backgrounds
    static let background = Color(hex: "0D0D0D")
    static let cardBackground = Color(hex: "1A1A2E")
    static let cardBackgroundMid = Color(hex: "1E1E38")
    static let cardBackgroundLight = Color(hex: "222240")

    // MARK: - Borders
    static let border = Color(hex: "7C3AED").opacity(0.18)
    static let borderStrong = Color(hex: "7C3AED").opacity(0.35)

    // MARK: - Accent Colors
    static let accent = Color(hex: "7C3AED")        // Purple
    static let accentLight = Color(hex: "A78BFA")    // Light purple
    static let accentBright = Color(hex: "A855F7")   // For gradient end
    static let accentGlow = Color(hex: "7C3AED").opacity(0.3)

    // MARK: - Semantic Colors
    static let streak = Color(hex: "F59E0B")         // Amber/flame
    static let success = Color(hex: "10B981")        // Green
    static let warning = Color(hex: "F59E0B")        // Amber
    static let error = Color(hex: "EF4444")          // Red

    // MARK: - Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "9CA3AF")
    static let textMuted = Color(hex: "6B7280")

    // MARK: - Mood Tag Colors
    static let moodCozy = Color(hex: "F97316")
    static let moodIntense = Color(hex: "EF4444")
    static let moodReflective = Color(hex: "6366F1")
    static let moodFun = Color(hex: "FBBF24")
    static let moodDark = Color(hex: "6B7280")
    static let moodAdventurous = Color(hex: "10B981")
    static let moodEmotional = Color(hex: "EC4899")
    static let moodMindBending = Color(hex: "8B5CF6")

    // MARK: - Gradients
    /// Banner gradient used by streak / level / featured-quote cards.
    static let bannerGradient = LinearGradient(
        colors: [Color(hex: "16143A"), Color(hex: "231550")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Primary CTA button gradient.
    static let primaryButtonGradient = LinearGradient(
        colors: [accent, accentBright],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Cover palettes (gradient pairs for placeholder book covers)
    static let coverPalettes: [(Color, Color)] = [
        (Color(hex: "3730A3"), Color(hex: "7C3AED")),
        (Color(hex: "065F46"), Color(hex: "10B981")),
        (Color(hex: "7C2D12"), Color(hex: "F97316")),
        (Color(hex: "1E3A5F"), Color(hex: "38BDF8")),
        (Color(hex: "4C1D95"), Color(hex: "A78BFA")),
        (Color(hex: "831843"), Color(hex: "F472B6")),
    ]

    static func coverPalette(seed: String) -> (Color, Color) {
        let hash = abs(seed.hashValue)
        return coverPalettes[hash % coverPalettes.count]
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
