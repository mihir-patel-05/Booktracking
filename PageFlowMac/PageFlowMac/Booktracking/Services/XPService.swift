import Foundation

struct XPBreakdown {
    let sessionCompletion: Int
    let moodTags: Int
    let reflection: Int
    let note: Int
    let quote: Int

    var total: Int {
        min(sessionCompletion + moodTags + reflection + note + quote, XPValues.maxPerSession)
    }
}

enum XPService {
    static func calculate(
        hasMoods: Bool,
        hasReflection: Bool,
        hasNote: Bool,
        hasQuote: Bool
    ) -> XPBreakdown {
        XPBreakdown(
            sessionCompletion: XPValues.sessionCompletion,
            moodTags: hasMoods ? XPValues.moodTagsSelected : 0,
            reflection: hasReflection ? XPValues.journalReflection : 0,
            note: hasNote ? XPValues.sessionNote : 0,
            quote: hasQuote ? XPValues.quoteSaved : 0
        )
    }
}
