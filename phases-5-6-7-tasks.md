# Phases 5, 6 & 7 — Implementation Task Lists

## Context
Phases 1-4 are complete (auth, book library, timer, journal flow + XP). The remaining phases add: Notes/Quotes polish (5), Stats/Streaks/Charts (6), and Production polish (7). Each phase has a numbered task list grouped so independent tasks can run in parallel.

---

# Phase 5: Notes Library & Quotes Vault

## Group A — Tag Infrastructure (no dependencies)

**Task 1** — `Utilities/Constants.swift` (modify): Add `NoteTag` enum (keyIdea, question, characterNote, plotPoint, vocabulary, theme, personalReflection, criticism) with `rawValue`, `emoji`, `color` computed properties. Pattern: same as `MoodTag`.

**Task 2** — `Utilities/Theme.swift` (modify): Add 4-6 tag color constants (e.g. `tagKeyIdea`, `tagQuestion`) following the `moodCozy` pattern.

## Group B — Note Tag UI (depends on A)

**Task 3** — `Components/NoteTagChip.swift` (NEW): Reusable chip like MoodTagPill but typed to `NoteTag`. Accepts `tag`, `isSelected`, `action`.

**Task 4** — `Views/Notes/AddNoteView.swift` (modify): Add `@State selectedTags: Set<NoteTag>`. Add Tags section with NoteTagChip grid. Pass tags to SessionNote init.

**Task 5** — `Views/Notes/NoteDetailView.swift` (modify): Add tag display/editing section. Add delete button in toolbar with confirmation alert.

**Task 6** — `Views/Notes/NotesView.swift` (modify): Show tag chips on each note card (max 3 + overflow). Use NoteTagChip in non-interactive mode.

**Task 7** — `Views/Notes/NotesView.swift` (modify): Add `@State expandedNoteID: UUID?`. Tapping card expands to show full content + all tags + chapter ref. Animate with `.animation(.spring)`.

## Group C — Quotes Enhancements (no dependencies)

**Task 8** — `Components/QuoteCard.swift` (modify): Add share button (square.and.arrow.up icon).

**Task 9** — `Components/QuoteShareImageView.swift` (NEW): Styled card view for sharing. Use `ImageRenderer` to convert to UIImage. Wire into QuoteCard share button via ShareLink.

**Task 10** — `Views/Quotes/QuotesView.swift` (modify): Add toolbar shuffle button. `@State randomQuote`. Present random quote in a sheet with large QuoteCard + dismiss.

**Task 11** — `Views/Quotes/QuotesView.swift` (modify): Add `.swipeActions(edge: .trailing)` with destructive delete on each quote row.

## Group D — Delete Sync (independent)

**Task 12** — `Models/DeletedRecord.swift` (NEW): `@Model` with `id`, `tableName`, `recordId`, `deletedAt`, `supabaseUserId`, `needsSync`.

**Task 13** — `App/PageFlowApp.swift` (modify): Add `DeletedRecord.self` to Schema array.

**Task 14** — `Services/Supabase/SyncService.swift` (modify): Add `syncDeletes()` method. Fetch DeletedRecords with `needsSync == true`, issue Supabase `.delete()` calls, then clean up. Call at start of `syncAll()`.

**Task 15** — Wire deletion tracking: In NotesView, QuotesView, NoteDetailView, BookDetailView — before `modelContext.delete()`, insert a `DeletedRecord` with the entity's table name and ID.

---

# Phase 6: Stats Dashboard, Streaks & Gamification

## Group A — StreakService (foundation, do first)

**Task 1** — `Services/StreakService.swift` (NEW): `@Observable` class with:
- `recordSession(stats:)` — update streak (extracted from TimerView.updateStreak)
- `checkMonthRollover(stats:)` — reset freezes if new month
- `useStreakFreeze(stats:) -> Bool` — use 1 of 2/month freezes
- `checkStreakStatus(stats:)` — called on app launch, auto-apply freeze or reset streak

**Task 2** — `App/PageFlowApp.swift` + `App/ContentView.swift` (modify): Register StreakService in environment. Call `checkStreakStatus` on app launch when authenticated.

**Task 3** — `Views/Timer/TimerView.swift` (modify): Replace inline `updateStreak()` with `streakService.recordSession(stats:)`.

## Group B — Charts & Visualizations (parallel with A)

**Task 4** — `Components/WeeklyBarChartView.swift` (NEW): Swift Charts `BarMark` for 7-day reading minutes. Purple bars, day labels on X-axis.

**Task 5** — `Components/ReadingHeatmapView.swift` (NEW): 4x7 grid of colored squares for last 28 days. Intensity based on reading minutes per day.

**Task 6** — `Components/VibeProfileView.swift` (NEW): Aggregate mood tags across sessions. Show ranked bars with emoji + name + proportion. Headline "Your Reading Vibe" with top 3.

**Task 7** — `Components/PersonalBestsView.swift` (NEW): Grid of StatCards showing: longest session, most sessions/day, total books completed, highest session XP.

**Task 8** — `Views/Stats/StatsView.swift` (modify): Add `import Charts`. Insert sections for weekly chart, heatmap, personal bests, vibe profile below existing content.

## Group C — Streak UI (depends on A)

**Task 9** — `Views/Home/HomeView.swift` (modify): Add streak freezes display (snowflake icons, X/2 remaining) + "Use Freeze" button below streak section.

**Task 10** — `Views/Stats/StatsView.swift` (modify): Add streak freezes remaining indicator to streak row.

## Group D — Weekly Summary (no dependencies)

**Task 11** — `Views/Home/HomeView.swift` (modify): Add `weeklySummarySection` between streak and currently reading. Show: total minutes, session count, books touched this week as compact stat row.

## Group E — Sync Verification

**Task 12** — `Services/StreakService.swift` (verify): Every mutation sets `stats.needsSync = true`. Verify SyncService DTO includes freeze fields.

---

# Phase 7: Polish, Accessibility, Sync Robustness & Edge Cases

## Group A — Empty States (no dependencies)

**Task 1** — Enhance empty states in: NotesView, QuotesView, StatsView, HomeView, BookLibraryView. Add CTA buttons ("Start a session", "Add a book") with navigation. Add accessibility labels. Ensure 44pt tap targets.

## Group B — Accessibility (no dependencies)

**Task 2** — VoiceOver labels: BookCard (`.accessibilityElement(children: .combine)`), QuoteCard, StatCard, MoodTagPill (selected trait), ProgressBar (`.accessibilityValue`), timer controls, NoteTagChip.

**Task 3** — Dynamic Type: Replace hardcoded `.system(size:)` with semantic fonts where possible. Add `.minimumScaleFactor(0.7)` for fixed-size displays (timer, icons).

**Task 4** — Tap targets: Ensure all interactive elements have `minHeight: 44`. Add `.contentShape(Rectangle())` where needed (MoodTagPill, StatusFilterPills, NoteTagChip).

**Task 5** — Contrast audit: Verify `textMuted` on `background` and `textSecondary` on `cardBackground` pass WCAG AA (4.5:1). Adjust Theme hex values if needed.

## Group C — Animations (no dependencies)

**Task 6** — TimerView: Add pulsing glow shadow on the active timer circle stroke.

**Task 7** — TimerView postSession: Animate "+X XP" with scale+opacity spring transition on save.

**Task 8** — HomeView: Add subtle vertical bounce animation on streak flame icon.

**Task 9** — NotesView: Polish card expand/collapse with `.matchedGeometryEffect` or spring animation.

## Group D — Sync Robustness (critical path)

**Task 10** — `SyncService.swift` (modify): Add `enum SyncError: LocalizedError` (networkUnavailable, authExpired, conflict, serverError, unknown). Add `lastError` property.

**Task 11** — `SyncService.swift` (modify): Add `withRetry(maxAttempts: 3)` helper with exponential backoff. Wrap all sync operations.

**Task 12** — `SyncService.swift` (modify): Add `pullFromSupabase(modelContext:userId:)` — fetch remote records, upsert into SwiftData. Last-write-wins by timestamp. `ContentView.swift`: call on app launch.

**Task 13** — `SyncService.swift` (modify): Conflict resolution in pull — compare timestamps, take newer. For UserStats, merge numerically (max of XP, streaks).

**Task 14** — `AuthService.swift` (modify): Add `refreshSessionIfNeeded() -> Bool`. `SyncService`: call before syncAll, abort with `.authExpired` if false.

**Task 15** — `Components/SyncErrorBanner.swift` (NEW) + `ContentView.swift` (modify): Dismissible error banner overlay. Auto-dismiss after 5s. "Retry" button.

## Group E — Data Export (independent)

**Task 16** — `Services/DataExportService.swift` (NEW): Static `exportJSON(books:sessions:notes:quotes:stats:) -> Data?`. Codable export structs. Single JSON with top-level keys.

**Task 17** — `Views/Stats/StatsView.swift` (modify): Toolbar export button with ShareLink for the JSON file.

## Group F — Edge Cases (independent)

**Task 18** — Zero-page books: `BookDetailView.swift` — show "Page count unknown" instead of progress bar when `totalPages == 0`.

**Task 19** — Long titles: Audit BookCard, QuoteCard, HomeView, NotesView. Ensure `.lineLimit(2)` + truncation + card `minHeight`.

**Task 20** — Month rollover: StreakService `checkMonthRollover` handles Dec-Jan correctly (uses Calendar month component).

**Task 21** — Multi-day gaps: StreakService `checkStreakStatus` — 2-day gap uses 1 freeze, 3-day uses 2, >3 days resets streak.

**Task 22** — Deleted book refs: Verify `quote.book?.title ?? "Unknown Book"` pattern everywhere books are optional (QuotesView, NotesView, QuoteCard).

---

## File Count Summary

| Phase | New Files | Modified Files |
|-------|-----------|----------------|
| 5 | 3 (NoteTagChip, QuoteShareImageView, DeletedRecord) | 8 |
| 6 | 5 (StreakService, WeeklyBarChart, Heatmap, VibeProfile, PersonalBests) | 5 |
| 7 | 2 (SyncErrorBanner, DataExportService) | ~15 |
