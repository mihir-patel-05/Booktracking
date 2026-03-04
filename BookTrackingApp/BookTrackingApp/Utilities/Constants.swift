import SwiftUI

// MARK: - Book Status

enum BookStatus: String, CaseIterable, Codable {
    case wantToRead = "Want to Read"
    case currentlyReading = "Currently Reading"
    case completed = "Completed"
    case abandoned = "Abandoned"

    var icon: String {
        switch self {
        case .wantToRead: return "bookmark"
        case .currentlyReading: return "book.fill"
        case .completed: return "checkmark.circle.fill"
        case .abandoned: return "xmark.circle"
        }
    }
}

// MARK: - Mood Tags

enum MoodTag: String, CaseIterable, Codable {
    case cozy = "Cozy"
    case intense = "Intense"
    case reflective = "Reflective"
    case fun = "Fun"
    case dark = "Dark"
    case adventurous = "Adventurous"
    case emotional = "Emotional"
    case mindBending = "Mind-bending"

    var emoji: String {
        switch self {
        case .cozy: return "🧸"
        case .intense: return "🔥"
        case .reflective: return "🪞"
        case .fun: return "🎉"
        case .dark: return "🌑"
        case .adventurous: return "🧭"
        case .emotional: return "💔"
        case .mindBending: return "🌀"
        }
    }

    var color: Color {
        switch self {
        case .cozy: return Theme.moodCozy
        case .intense: return Theme.moodIntense
        case .reflective: return Theme.moodReflective
        case .fun: return Theme.moodFun
        case .dark: return Theme.moodDark
        case .adventurous: return Theme.moodAdventurous
        case .emotional: return Theme.moodEmotional
        case .mindBending: return Theme.moodMindBending
        }
    }
}

// MARK: - Reader Levels

enum ReaderLevel: String, CaseIterable {
    case casualReader = "Casual Reader"
    case pageTurner = "Page Turner"
    case bookworm = "Bookworm"
    case scholar = "Scholar"
    case sage = "Sage"
    case grandmaster = "Grandmaster"

    var xpThreshold: Int {
        switch self {
        case .casualReader: return 0
        case .pageTurner: return 100
        case .bookworm: return 300
        case .scholar: return 600
        case .sage: return 1000
        case .grandmaster: return 1500
        }
    }

    var xpForNext: Int {
        switch self {
        case .casualReader: return 100
        case .pageTurner: return 300
        case .bookworm: return 600
        case .scholar: return 1000
        case .sage: return 1500
        case .grandmaster: return 1500 // Max level
        }
    }

    var icon: String {
        switch self {
        case .casualReader: return "book"
        case .pageTurner: return "book.fill"
        case .bookworm: return "books.vertical"
        case .scholar: return "graduationcap"
        case .sage: return "sparkles"
        case .grandmaster: return "crown"
        }
    }

    static func level(for xp: Int) -> ReaderLevel {
        let sorted = ReaderLevel.allCases.reversed()
        for level in sorted {
            if xp >= level.xpThreshold {
                return level
            }
        }
        return .casualReader
    }
}

// MARK: - XP Values

enum XPValues {
    static let sessionCompletion = 5
    static let journalReflection = 5
    static let sessionNote = 5
    static let moodTagsSelected = 5
    static let quoteSaved = 5
    static let maxPerSession = 25
}

// MARK: - Timer Presets

enum TimerPreset: Int, CaseIterable {
    case fifteen = 15
    case twentyFive = 25
    case thirty = 30
    case fortyFive = 45

    var label: String {
        "\(rawValue)m"
    }
}

// MARK: - Reflection Prompts

enum Prompts {
    static let reflections: [String] = [
        "Did anything surprise you?",
        "Summarize what happened in one sentence.",
        "What idea stood out the most?",
        "Did this change how you think about something?",
        "What question does this raise for you?",
        "How did this section make you feel?",
        "What would you tell a friend about this part?",
        "Did anything remind you of your own life?",
        "What was the most vivid image or scene?",
        "If you could ask the author one question, what would it be?",
        "What's one thing you want to remember from this session?",
        "Did your opinion on anything shift while reading?"
    ]

    static let notes: [String] = [
        "What's one key idea from this session?",
        "How does this connect to something you already know?",
        "What concept would you want to explain to someone?",
        "What's the most useful takeaway?",
        "Did you learn a new word or concept?",
        "What argument or point was most compelling?",
        "What would you highlight if you owned this book?",
        "What's one thing you want to apply from this reading?"
    ]
}
