import Foundation
import SwiftData

@Model
final class UserStats {
    var id: UUID
    var totalXP: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastSessionDate: Date?
    var streakFreezesUsedThisMonth: Int
    var streakFreezeMonthMarker: Int
    var needsSync: Bool
    var supabaseUserId: String?

    var currentLevel: ReaderLevel {
        ReaderLevel.level(for: totalXP)
    }

    var xpForNextLevel: Int {
        currentLevel.xpForNext - totalXP
    }

    var levelProgress: Double {
        let current = currentLevel
        let base = current.xpThreshold
        let next = current.xpForNext
        guard next > base else { return 1.0 }
        return Double(totalXP - base) / Double(next - base)
    }

    init() {
        self.id = UUID()
        self.totalXP = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.streakFreezesUsedThisMonth = 0
        self.streakFreezeMonthMarker = Calendar.current.component(.month, from: Date())
        self.needsSync = true
    }
}
