import SwiftUI

struct QuoteSaveStepView: View {
    @Binding var quoteText: String
    let book: Book
    let elapsedTime: String
    let xpBreakdown: XPBreakdown

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Quote section
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "quote.opening")
                            .foregroundStyle(Theme.accent)
                        Text("Save a Quote")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                    }

                    TextEditor(text: $quoteText)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(Theme.textPrimary)
                        .frame(minHeight: 100)
                        .padding(12)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Session Summary
                VStack(alignment: .leading, spacing: 16) {
                    Text("Session Summary")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)

                    VStack(spacing: 12) {
                        // Book + duration
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundStyle(Theme.accent)
                            Text(book.title)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Text(elapsedTime)
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }

                        Divider()
                            .overlay(Theme.cardBackgroundLight)

                        // XP Breakdown
                        xpRow(label: "Session Complete", xp: xpBreakdown.sessionCompletion)
                        xpRow(label: "Mood Tags", xp: xpBreakdown.moodTags)
                        xpRow(label: "Reflection", xp: xpBreakdown.reflection)
                        xpRow(label: "Session Note", xp: xpBreakdown.note)
                        xpRow(label: "Quote Saved", xp: xpBreakdown.quote)

                        Divider()
                            .overlay(Theme.cardBackgroundLight)

                        // Total
                        HStack {
                            Text("Total")
                                .font(.subheadline.bold())
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text("+\(xpBreakdown.total) XP")
                                .font(.subheadline.bold())
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    .padding(16)
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }

    private func xpRow(label: String, xp: Int) -> some View {
        HStack {
            Image(systemName: xp > 0 ? "checkmark.circle.fill" : "minus.circle")
                .font(.caption)
                .foregroundStyle(xp > 0 ? Theme.success : Theme.textMuted)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(xp > 0 ? Theme.textPrimary : Theme.textMuted)
            Spacer()
            Text(xp > 0 ? "+\(xp) XP" : "—")
                .font(.subheadline)
                .foregroundStyle(xp > 0 ? Theme.accentLight : Theme.textMuted)
        }
    }
}
