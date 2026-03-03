# PageFlow — Phased Implementation Plan

## Context

PageFlow is a gamified iOS book tracking app that transforms reading into a reflective habit. The repo currently contains only a PRD (`prd.md`) — no Xcode project, no Swift files. This plan breaks the full build into 7 phases, each producing a testable/runnable app state.

**Target platforms:** iOS (v1), iPadOS & macOS (future)

**Tech stack:** Swift, SwiftUI, SwiftData (offline-first local store), Supabase (backend DB + Auth + sync), iOS 17+, dark mode only, Open Library API, Swift Charts, UserNotifications, SPM for dependencies.

**Data architecture:** Offline-first — SwiftData is the primary local store. Supabase is the cloud backend for persistence, auth, and future multi-device sync. Writes go to SwiftData first, then sync to Supabase in the background.

**Auth:** Supabase Auth with Sign in with Apple from v1.

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
│   │   ├── Auth/
│   │   ├── Home/
│   │   ├── Timer/
│   │   │   └── JournalFlow/
│   │   ├── Notes/
│   │   ├── Quotes/
│   │   ├── Stats/
│   │   └── Books/
│   ├── Services/
│   │   ├── Supabase/
│   │   │   ├── SupabaseManager.swift
│   │   │   ├── AuthService.swift
│   │   │   └── SyncService.swift
│   ├── Components/
│   └── Utilities/
```

---

## Phase 1: Project Scaffold, Data Models, Supabase, Auth & Tab Navigation

**Goal:** Running app with Supabase Auth (Sign in with Apple), all SwiftData models defined, Supabase tables created, dark-mode theme, and 5-tab navigation behind auth.

**Build:**

### 1a. Xcode Project & Dependencies
- Xcode project setup (iOS 17, iPhone, dark mode)
- Add `supabase-swift` via SPM (`https://github.com/supabase/supabase-swift`)

### 1b. Supabase Tables & RLS
- Create tables matching the data models:
  - `books` — id (uuid PK), user_id (uuid FK→auth.users), title, author, cover_url, total_pages, current_page, status, date_added, date_completed
  - `reading_sessions` — id, user_id, book_id (FK→books), start_date, duration_seconds, mood_tags (text[]), reflection_prompt, reflection_text, xp_earned
  - `session_notes` — id, user_id, book_id (FK→books), session_id (FK→reading_sessions), title, content, tags (text[]), chapter_reference, date_created
  - `quotes` — id, user_id, book_id (FK→books), session_id (FK→reading_sessions nullable), text, date_created
  - `user_stats` — id, user_id (unique), total_xp, current_streak, longest_streak, last_session_date, streak_freezes_used_this_month, streak_freeze_month_marker
- RLS policies: all tables restricted to `auth.uid() = user_id`
- Enable Sign in with Apple in Supabase Auth settings

### 1c. SwiftData Models (offline-first local store)
- `Book` — title, author, coverURL, totalPages, currentPage, status enum, relationships to sessions/notes/quotes, supabaseId for sync
- `ReadingSession` — book relationship, startDate, durationSeconds, moodTags, reflectionPrompt/Text, xpEarned
- `SessionNote` — book + session relationships, title, content, tags, chapterReference, dateCreated
- `Quote` — book + optional session relationship, text, dateCreated
- `UserStats` — totalXP, currentStreak, longestStreak, lastSessionDate, streakFreezes

### 1d. Supabase Client & Auth
- `SupabaseManager` — singleton holding the Supabase client, initialized with project URL + anon key
- `AuthService` — Sign in with Apple flow, session management, sign out
- Auth gate in app: show login screen if not authenticated, main app if authenticated

### 1e. Sync Foundation
- `SyncService` — basic structure for background sync (SwiftData ↔ Supabase). Full sync logic can be built incrementally in later phases, but the scaffold is here.

### 1f. UI Shell
- `ModelContainer` configuration in app entry point
- `TabView` with 5 tabs: Home, Timer, Notes, Quotes, Stats (placeholder views)
- `Theme.swift` — color palette for dark mode
- `Constants.swift` — `BookStatus`, `MoodTag`, `ReaderLevel` enums, reflection/note prompt banks
- `AuthView` — Sign in with Apple button, styled for dark mode

**Files:**

| File | Purpose |
|---|---|
| `App/PageFlowApp.swift` | Entry point, ModelContainer, Supabase init |
| `App/ContentView.swift` | Auth gate + TabView |
| `Models/Book.swift` | Book model |
| `Models/ReadingSession.swift` | Session model |
| `Models/SessionNote.swift` | Note model |
| `Models/Quote.swift` | Quote model |
| `Models/UserStats.swift` | Stats/streak model |
| `Services/Supabase/SupabaseManager.swift` | Supabase client singleton |
| `Services/Supabase/AuthService.swift` | Sign in with Apple + session |
| `Services/Supabase/SyncService.swift` | Sync scaffold |
| `Views/Auth/AuthView.swift` | Login screen |
| `Utilities/Theme.swift` | Colors, fonts |
| `Utilities/Constants.swift` | Enums, prompts |
| `Views/Home/HomeView.swift` | Placeholder |
| `Views/Timer/TimerView.swift` | Placeholder |
| `Views/Notes/NotesView.swift` | Placeholder |
| `Views/Quotes/QuotesView.swift` | Placeholder |
| `Views/Stats/StatsView.swift` | Placeholder |

**Supabase SQL:**
- Migration script for all 5 tables with RLS policies

**Verify:** App launches, shows Sign in with Apple, authenticates, lands on 5-tab home. SwiftData initializes. Supabase connection works.

---

## Phase 2: Book Library

**Goal:** Users can add books (manually + API search), browse by status, update progress. Home tab shows currently reading books. Books sync to Supabase.

**Build:**
- Manual book entry form (title, author, pages, optional cover URL)
- `BookSearchService` — Open Library API integration (`/search.json`)
- Book search UI with results list
- Book library view with status filter pills
- Book detail view with progress update, status picker, delete
- `BookCard` & `ProgressBar` components
- Home screen: time-of-day greeting + currently reading horizontal scroll
- Sync: books written to SwiftData first, then pushed to Supabase

**Verify:** Search "Atomic Habits", add it, see it on Home, update page progress. Book appears in Supabase dashboard.

---

## Phase 3: Reading Timer

**Goal:** Functional countdown timer tied to a book, with background execution, notifications, pause/resume.

**Build:**
- `TimerService` (`@Observable`) — state machine, Date-based accuracy
- `NotificationService` — local notifications
- Timer UI: book selector, presets (15/25/30/45m + custom), circular progress, controls
- Background handling via `scenePhase` + stored `targetEndDate`

**Verify:** Select book, start 1-min timer, minimize app, receive notification. Pause/resume works.

---

## Phase 4: Post-Session Journal Flow & XP

**Goal:** 3-step guided journal after timer. Sessions saved locally + synced. XP calculated.

**Build:**
- Journal flow container (3-step navigation)
- Step 1: Mood & Reflection — mood tags, rotating prompt, free-form text
- Step 2: Session Notes — title, content, tags, chapter ref
- Step 3: Quote & Save — quote field, summary card
- `XPService` — +5 base, +5 reflection, +5 note, +5 moods, +5 quote
- Save to SwiftData → sync sessions/notes/quotes to Supabase

**Verify:** Complete timer → fill all steps → save → 25 XP. Data appears in Supabase.

---

## Phase 5: Notes Library & Quotes Vault

**Goal:** Notes and Quotes tabs functional with search, filtering, share.

**Build:**
- Notes tab: search, book filter pills, expandable cards, tag chips
- Quotes tab: search, share-as-image, random quote, swipe-to-delete
- Deletes sync to Supabase

**Verify:** Search/filter/share/delete all work. Deletions reflected in Supabase.

---

## Phase 6: Stats Dashboard, Streaks & Gamification

**Goal:** Stats tab with charts/heatmap. Streak tracking. Leveling. Home completed.

**Build:**
- `StreakService` — streak logic, freeze (2/month)
- Leveling: Casual Reader(0) → Page Turner(100) → Bookworm(300) → Scholar(600) → Sage(1000) → Grandmaster(1500)
- Stats tab: XP card, weekly chart, 28-day heatmap, personal bests, vibe profile
- Home: streak banner, weekly summary, quick stats
- User stats synced to Supabase

**Verify:** Charts accurate, streaks work, Home shows live data.

---

## Phase 7: Polish, Accessibility, Sync Robustness & Edge Cases

**Goal:** Production quality — accessibility, animations, error handling, robust sync, data export.

**Build:**
- Empty states for all views
- Accessibility: VoiceOver, Dynamic Type, tap targets, contrast
- Animations: timer, XP pop-up, streak flame, card expand
- Error handling: network failures, auth expiry, sync conflicts
- Robust sync: conflict resolution, retry logic, pull-on-launch
- Data export: JSON via `ShareLink`
- Edge cases: zero pages, long titles, month rollover, multi-day gaps

**Verify:** Full VoiceOver walkthrough. Offline → online sync works. Export valid JSON.

---

## Phase Dependency Graph

```
Phase 1 (Foundation + Supabase + Auth)
  └→ Phase 2 (Books)
       └→ Phase 3 (Timer)
            └→ Phase 4 (Journal + XP)
                 ├→ Phase 5 (Notes + Quotes)  ← can run in parallel
                 └→ Phase 6 (Stats + Streaks) ← can run in parallel
                      └→ Phase 7 (Polish + Sync)
```

**Estimated total:** ~55-60 Swift files + Supabase migration SQL.
