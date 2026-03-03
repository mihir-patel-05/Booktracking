# PageFlow — Phased Implementation Plan

## Context

PageFlow is a gamified iOS book tracking app that transforms reading into a reflective habit. The repo currently contains only a PRD (`prd.md`) — no Xcode project, no Swift files. This plan breaks the full build into 7 phases, each producing a testable/runnable app state.

**Tech stack:** Swift, SwiftUI, SwiftData, iOS 17+, iPhone only, dark mode only, Open Library API, Swift Charts, UserNotifications.

---

## Project Structure

```
PageFlow/
├── PageFlow.xcodeproj
├── PageFlow/
│   ├── App/
│   │   ├── PageFlowApp.swift
│   │   └── ContentView.swift
│   ├── Models/
│   ├── Views/
│   │   ├── Home/
│   │   ├── Timer/
│   │   │   └── JournalFlow/
│   │   ├── Notes/
│   │   ├── Quotes/
│   │   ├── Stats/
│   │   └── Books/
│   ├── Services/
│   ├── Components/
│   └── Utilities/
```

---

## Phase 1: Project Scaffold, Data Models & Tab Navigation

**Goal:** Running app with 5 tabs (placeholders), all SwiftData models defined, dark-mode theme established.

**Build:**
- Xcode project setup (iOS 17, iPhone, dark mode)
- SwiftData models with relationships:
  - `Book` — title, author, coverURL, totalPages, currentPage, status enum, relationships to sessions/notes/quotes
  - `ReadingSession` — book relationship, startDate, durationSeconds, moodTags, reflectionPrompt/Text, xpEarned
  - `SessionNote` — book + session relationships, title, content, tags, chapterReference, dateCreated
  - `Quote` — book + optional session relationship, text, dateCreated
  - `UserStats` — totalXP, currentStreak, longestStreak, lastSessionDate, streakFreezes
- `ModelContainer` configuration in app entry point
- `TabView` with 5 tabs: Home, Timer, Notes, Quotes, Stats (placeholder views)
- `Theme.swift` — color palette for dark mode
- `Constants.swift` — `BookStatus`, `MoodTag`, `ReaderLevel` enums, reflection/note prompt banks

**Files:**

| File | Purpose |
|---|---|
| `App/PageFlowApp.swift` | Entry point, ModelContainer |
| `App/ContentView.swift` | TabView with 5 tabs |
| `Models/Book.swift` | Book model |
| `Models/ReadingSession.swift` | Session model |
| `Models/SessionNote.swift` | Note model |
| `Models/Quote.swift` | Quote model |
| `Models/UserStats.swift` | Stats/streak model |
| `Utilities/Theme.swift` | Colors, fonts |
| `Utilities/Constants.swift` | Enums, prompts |
| `Views/*/___View.swift` | 5 placeholder tab views |

**Verify:** App launches in simulator, 5 tabs visible, SwiftData initializes without crash.

---

## Phase 2: Book Library

**Goal:** Users can add books (manually + API search), browse by status, update progress. Home tab shows currently reading books.

**Build:**
- Manual book entry form (title, author, pages, optional cover URL)
- `BookSearchService` — Open Library API integration (`/search.json`)
- Book search UI with results list
- Book library view with status filter pills
- Book detail view with progress update (currentPage stepper/slider), status picker, delete
- `BookCard` component — cover, title, author, progress bar
- `ProgressBar` component
- Home screen: time-of-day greeting + currently reading horizontal scroll

**Files:**

| File | Purpose |
|---|---|
| `Services/BookSearchService.swift` | Open Library API |
| `Views/Books/BookLibraryView.swift` | Library by status |
| `Views/Books/AddBookView.swift` | Manual entry form |
| `Views/Books/BookSearchView.swift` | API search UI |
| `Views/Books/BookDetailView.swift` | Detail + progress |
| `Components/BookCard.swift` | Reusable card |
| `Components/ProgressBar.swift` | Progress bar |
| `Views/Home/HomeView.swift` | Greeting + currently reading |

**Verify:** Search "Atomic Habits", add it, see it on Home, update page progress, change status.

---

## Phase 3: Reading Timer

**Goal:** Functional countdown timer tied to a book, with background execution, notifications, pause/resume.

**Build:**
- `TimerService` (`@Observable`) — state machine (idle → running → paused → completed), Date-based accuracy for background resilience
- `NotificationService` — permission request, schedule/cancel local notifications
- Timer UI: book selector, duration presets (15/25/30/45m + custom), circular progress indicator, play/pause/end buttons
- `CircularTimerView` component — `Circle` with `trim` animation
- Background handling via `scenePhase` + stored `targetEndDate`
- Tapping book on Home navigates to Timer with book pre-selected

**Files:**

| File | Purpose |
|---|---|
| `Services/TimerService.swift` | Timer logic |
| `Services/NotificationService.swift` | Notifications |
| `Views/Timer/TimerView.swift` | Full timer UI |
| `Views/Timer/BookSelectorView.swift` | Book picker |
| `Components/CircularTimerView.swift` | Circular progress |
| `Components/DurationPresetsView.swift` | Preset buttons |

**Verify:** Select book, start 1-min timer, minimize app, receive notification. Pause/resume works. Early end creates session record.

---

## Phase 4: Post-Session Journal Flow & XP

**Goal:** 3-step guided journal after timer completion. Sessions saved with all data. XP calculated and awarded.

**Build:**
- Journal flow container — full-screen, 3-step navigation with step indicator, state preserved across steps
- **Step 1 (Mood & Reflection):** mood tag grid (multi-select), rotating prompt with refresh, free-form text field
- **Step 2 (Session Notes):** rotating prompt, title field, content field, comma-separated tags, chapter ref, skip option
- **Step 3 (Quote & Save):** quote text field, session summary card, save button
- Save logic: update `ReadingSession`, create `SessionNote` if filled, create `Quote` if filled
- `XPService` — calculate XP: +5 base, +5 reflection, +5 note, +5 moods, +5 quote (max 25)
- Confirmation screen with XP breakdown
- `MoodTagChip` component (toggleable capsule)

**Files:**

| File | Purpose |
|---|---|
| `Views/Timer/JournalFlow/JournalFlowView.swift` | 3-step container |
| `Views/Timer/JournalFlow/MoodReflectionView.swift` | Step 1 |
| `Views/Timer/JournalFlow/SessionNoteEntryView.swift` | Step 2 |
| `Views/Timer/JournalFlow/QuoteSaveView.swift` | Step 3 |
| `Views/Timer/JournalFlow/SessionConfirmationView.swift` | XP breakdown |
| `Services/XPService.swift` | XP calculation |
| `Components/MoodTagChip.swift` | Mood tag chip |
| `Components/StepIndicator.swift` | Progress dots |

**Verify:** Complete timer → fill all 3 steps → save → see 25 XP. Also test skipping everything → 5 XP. Verify session/note/quote persist.

---

## Phase 5: Notes Library & Quotes Vault

**Goal:** Notes and Quotes tabs fully functional with search, filtering, and interactions.

**Build:**
- **Notes tab:** total count header, search bar (`.searchable`), book filter pills, expandable note cards (title/book/date/preview → full content + tag chips), reverse chronological sort
- **Quotes tab:** search bar, quote cards (styled text + book + date), share-as-image (`ImageRenderer`), random quote button (avoids consecutive repeat), swipe-to-delete
- `QuoteShareCard` — styled view for image export (dark bg, typography)
- `TagChip`, `BookFilterPills` components

**Files:**

| File | Purpose |
|---|---|
| `Views/Notes/NotesView.swift` | Notes library |
| `Views/Notes/NoteCardView.swift` | Expandable card |
| `Components/TagChip.swift` | `#tag` chip |
| `Components/BookFilterPills.swift` | Filter scroll |
| `Views/Quotes/QuotesView.swift` | Quotes vault |
| `Views/Quotes/QuoteCardView.swift` | Quote card |
| `Views/Quotes/QuoteShareCard.swift` | Share image view |
| `Services/ShareImageService.swift` | ImageRenderer logic |

**Verify:** After several sessions with notes/quotes: search works, book filter works, share generates image, random quote works, delete works.

---

## Phase 6: Stats Dashboard, Streaks & Gamification

**Goal:** Stats tab with charts/heatmap/bests. Streak tracking. Leveling system. Home screen completed.

**Build:**
- `StreakService` — increment/reset logic on session save, streak freeze (2/month), month rollover
- Leveling in `XPService`/`UserStats` — thresholds: Casual Reader(0) → Page Turner(100) → Bookworm(300) → Scholar(600) → Sage(1000) → Grandmaster(1500)
- **Stats tab:** XP/level card with progress bar, weekly bar chart (Swift Charts), 28-day heatmap (custom grid), personal bests (longest session, biggest week, fastest book, longest streak), reading vibe profile (mood tag breakdown + insight text)
- **Home completion:** streak banner (flame icon + count), weekly reading time summary, quick stats row (books this year, hours read, total notes)
- Streak freeze UI

**Files:**

| File | Purpose |
|---|---|
| `Services/StreakService.swift` | Streak logic |
| `Views/Stats/StatsView.swift` | Full dashboard |
| `Views/Stats/XPLevelCard.swift` | Level display |
| `Views/Stats/WeeklyChartView.swift` | Bar chart |
| `Views/Stats/HeatmapView.swift` | 28-day grid |
| `Views/Stats/PersonalBestsView.swift` | Bests section |
| `Views/Stats/VibeProfileView.swift` | Mood breakdown |
| `Views/Home/StreakBannerView.swift` | Streak component |
| `Views/Home/QuickStatsRow.swift` | Stats row |

**Verify:** After multiple sessions across days: charts accurate, heatmap reflects activity, XP level correct, streak increments, Home shows live data.

---

## Phase 7: Polish, Accessibility & Edge Cases

**Goal:** Production-quality pass — accessibility, animations, error handling, data export, empty states.

**Build:**
- Empty states for all list views (friendly messaging + SF Symbols)
- Accessibility: `.accessibilityLabel`/`.accessibilityHint` on all elements, 44x44pt tap targets, Dynamic Type support, VoiceOver testing, WCAG AA contrast
- Animations: circular timer progress, XP pop-up, streak flame pulse, card expand/collapse
- Error handling: network failures in book search, notification permission denial, SwiftData errors
- Data export: JSON export of notes/quotes via `ShareLink`/`fileExporter`
- Edge cases: zero pages (division by zero), long titles, month rollover for streak freezes, multi-day gap streak reset
- Optional lightweight onboarding (single welcome screen)

**Files:**

| File | Purpose |
|---|---|
| `Components/EmptyStateView.swift` | Reusable empty state |
| `Services/ExportService.swift` | JSON serialization |
| `Views/Settings/ExportView.swift` | Export UI |
| `Views/Onboarding/WelcomeView.swift` | First-launch screen |

**Verify:** Full VoiceOver walkthrough. Export produces valid JSON. Empty states on fresh install. Animations smooth. Edge cases handled.

---

## Phase Dependency Graph

```
Phase 1 (Foundation)
  └→ Phase 2 (Books)
       └→ Phase 3 (Timer)
            └→ Phase 4 (Journal + XP)
                 ├→ Phase 5 (Notes + Quotes)  ← can run in parallel
                 └→ Phase 6 (Stats + Streaks) ← can run in parallel
                      └→ Phase 7 (Polish)
```

**Estimated total:** ~50-55 Swift files across models, services, views, and components.
