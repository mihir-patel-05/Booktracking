import SwiftUI

struct QuoteSaveStepView: View {
    @Binding var quoteText: String
    let book: Book
    let elapsedTime: String
    let xpBreakdown: XPBreakdown

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 0) {
                    SectionLabel("Save a Quote")
                    HStack(alignment: .top, spacing: 12) {
                        BookCoverView(book: book, size: .sm)
                        ZStack(alignment: .topLeading) {
                            if quoteText.isEmpty {
                                Text("\u{201C}A passage worth remembering...\u{201D}")
                                    .font(.playfair(14))
                                    .italic()
                                    .foregroundStyle(Theme.textMuted)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }
                            TextEditor(text: $quoteText)
                                .scrollContentBackground(.hidden)
                                .font(.playfair(14))
                                .italic()
                                .foregroundStyle(Theme.textPrimary)
                                .tint(Theme.accentLight)
                                .frame(minHeight: 110)
                        }
                    }
                    .padding(14)
                    .designCard(cornerRadius: 14)
                }

                VStack(alignment: .leading, spacing: 0) {
                    SectionLabel("Session Summary")
                    VStack(spacing: 12) {
                        HStack(spacing: 10) {
                            BookCoverView(book: book, size: .sm)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.title)
                                    .font(.dmSans(13, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                    .lineLimit(1)
                                Text(elapsedTime)
                                    .font(.dmSans(11))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                        }

                        Divider().background(Theme.cardBackgroundLight)

                        xpRow(label: "Session Complete", xp: xpBreakdown.sessionCompletion)
                        xpRow(label: "Mood Tags", xp: xpBreakdown.moodTags)
                        xpRow(label: "Reflection", xp: xpBreakdown.reflection)
                        xpRow(label: "Session Note", xp: xpBreakdown.note)
                        xpRow(label: "Quote Saved", xp: xpBreakdown.quote)

                        Divider().background(Theme.cardBackgroundLight)

                        HStack {
                            Text("Total")
                                .font(.dmSans(14, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text("+\(xpBreakdown.total) XP")
                                .font(.playfair(18, weight: .bold))
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    .padding(16)
                    .designCard(cornerRadius: 14)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    private func xpRow(label: String, xp: Int) -> some View {
        HStack {
            Image(systemName: xp > 0 ? "checkmark.circle.fill" : "minus.circle")
                .font(.system(size: 12))
                .foregroundStyle(xp > 0 ? Theme.success : Theme.textMuted)
            Text(label)
                .font(.dmSans(13))
                .foregroundStyle(xp > 0 ? Theme.textPrimary : Theme.textMuted)
            Spacer()
            Text(xp > 0 ? "+\(xp) XP" : "—")
                .font(.dmSans(12, weight: .semibold))
                .foregroundStyle(xp > 0 ? Theme.accentLight : Theme.textMuted)
        }
    }
}
