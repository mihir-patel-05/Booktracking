# Product Requirements Document: PageFlow

## Overview

PageFlow is a gamified iOS book tracking app that transforms reading into a rewarding, reflective habit. Users track reading sessions with a customizable timer, capture learnings through guided prompts, save quotes, tag moods, and monitor progress through streaks, XP, and detailed stats. The app sits at the intersection of a reading tracker, a personal knowledge base, and a habit-building tool.

## Problem Statement

Existing book tracking apps (Goodreads, StoryGraph, Bookly) focus on cataloging — what you've read and how much. They fail to capture *what you learned* or *how reading made you feel*. Readers finish books and forget key ideas within weeks. There's no lightweight, enjoyable way to build a personal reading journal that doubles as a knowledge base without it feeling like homework.

## Target Audience

- **Primary:** Adults aged 20–40 who read regularly (5+ books/year) and want to retain more from what they read.
- **Secondary:** Aspiring readers who struggle with consistency and need motivation (streaks, gamification) to build a habit.
- **Tertiary:** Students and lifelong learners who use reading as a primary tool for self-improvement.

## Core Value Proposition

Every reading session becomes a building block — tracked, reflected on, and stored. By the time you finish a book, you have a personal journal of ideas, moods, and quotes without ever sitting down to "write a book summary."

---

## Feature Requirements

### 1. Book Library

**Priority:** P0 (Must Have)

**Description:** Users can add and manage books they are currently reading, have completed, or want to read.

**Functional Requirements:**

- Users can add books manually by entering title, author, total page count, and an optional cover image.
- Users can search and add books via ISBN lookup or title search using an integrated book API (Google Books or Open Library).
- Each book has a status: Want to Read, Currently Reading, Completed, or Abandoned.
- Users can set a current page number or percentage to track progress.
- The home screen displays Currently Reading books with progress bars.
- Each book card shows: title, author, cover, progress percentage, and total session notes count.
- Users can archive or delete books from their library.

**Acceptance Criteria:**

- A user can add a book and see it appear in their Currently Reading list within 2 seconds.
- Book search returns results within 3 seconds on a standard connection.
- Progress bar accurately reflects current page vs. total pages.

---

### 2. Reading Timer

**Priority:** P0 (Must Have)

**Description:** A customizable countdown timer that tracks individual reading sessions tied to a specific book.

**Functional Requirements:**

- Users select a book before starting a timer session.
- Preset timer durations are available: 15, 25, 30, and 45 minutes.
- Users can set a custom timer duration (1–180 minutes).
- The timer displays a circular progress indicator with elapsed/remaining time.
- The timer runs in the background and sends a local notification when complete.
- Users can pause and resume the timer mid-session.
- Users can end a session early, which still triggers the post-session journal flow.
- When the timer reaches zero, the app automatically transitions to the post-session journal flow.
- Session duration is recorded and stored regardless of whether the user completes the journal.

**Acceptance Criteria:**

- Timer countdown is accurate to within ±1 second over a 45-minute session.
- Background timer continues running when the app is minimized.
- Notification fires within 2 seconds of timer completion.

---

### 3. Post-Session Journal Flow

**Priority:** P0 (Must Have)

**Description:** A guided 3-step post-session flow that prompts users to reflect, take notes, and save quotes after each reading session.

#### Step 1: Mood & Reflection

**Functional Requirements:**

- Users are shown a set of mood/vibe tags to select from: cozy, intense, reflective, fun, dark, adventurous, emotional, mind-bending.
- Users can select multiple mood tags per session.
- A rotating reflection prompt is displayed (e.g., "Did anything surprise you?", "Summarize what happened in one sentence").
- Users can cycle through prompts by tapping a refresh button.
- A text field is provided for free-form reflection writing.
- All fields are optional — users can proceed without filling anything in.

**Acceptance Criteria:**

- At least 10 unique reflection prompts are available at launch.
- Prompt rotation is randomized and does not repeat the same prompt consecutively.

#### Step 2: Session Notes

**Functional Requirements:**

- A dedicated screen prompts users to capture what they learned during the session.
- A rotating learning-focused prompt is displayed (e.g., "What's one key idea from this session?", "How does this connect to something you already know?").
- Users can cycle through note prompts by tapping a refresh button.
- Users enter a note title (short label for the idea).
- Users enter full note content in a multi-line text field.
- Users can add comma-separated tags to categorize the note (e.g., "mindset, strategy, leadership").
- An optional chapter/section reference field is available.
- A "Skip notes for now" option is available to bypass this step.
- Notes are permanently stored and associated with the book and the session.

**Acceptance Criteria:**

- At least 8 unique note prompts are available at launch.
- Notes are saved and immediately visible in the Notes tab after session completion.
- Notes persist across app restarts.

#### Step 3: Quote & Save

**Functional Requirements:**

- Users can optionally save a quote or memorable passage from the session.
- A session summary card displays what was captured across all steps (moods selected, reflection written, note title).
- A "Save Session" button commits all data and displays a confirmation screen.
- The confirmation screen shows XP earned with a breakdown (base session XP + bonuses for journal, notes, mood tags, and quotes).

**Acceptance Criteria:**

- Users can navigate back and forth between all 3 steps without losing entered data.
- Save action completes within 1 second.

---

### 4. Session Notes Library

**Priority:** P0 (Must Have)

**Description:** A browsable, searchable collection of all notes captured across all reading sessions.

**Functional Requirements:**

- A dedicated Notes tab is accessible from the bottom navigation bar.
- The screen displays the total number of notes and the number of books with notes.
- A search bar allows full-text search across note titles, note content, and tags.
- Book filter pills allow users to filter notes by a specific book.
- Notes are displayed as expandable cards showing: title, book name, chapter reference, date, and a preview of the note content.
- Tapping a note card expands it to show the full note text and all associated tags.
- Tags are displayed as styled chips with a # prefix.
- Notes are sorted in reverse chronological order by default.

**Acceptance Criteria:**

- Search results update in real time as the user types.
- Filtering by book immediately updates the displayed notes.
- Notes from a newly completed session appear at the top of the list.

---

### 5. Quotes Vault

**Priority:** P1 (Should Have)

**Description:** A searchable collection of saved quotes and memorable passages, organized by book.

**Functional Requirements:**

- A dedicated Quotes tab is accessible from the bottom navigation bar.
- A search bar allows searching quotes by text content or book title.
- Each quote card displays: the quote text, the source book, and the date saved.
- Each quote card includes a "Share" action that generates a shareable image card with the quote, book title, and styled typography.
- A "Random Quote" button surfaces a random quote from the user's collection.
- Quotes can be deleted via swipe-to-delete or a long-press menu.

**Acceptance Criteria:**

- Share action generates an image card within 2 seconds.
- Random quote does not repeat the same quote on consecutive taps (unless the user has fewer than 3 quotes).

---

### 6. Stats & Gamification

**Priority:** P0 (Must Have)

**Description:** A stats dashboard that tracks reading habits and rewards consistency through streaks, XP, and leveling.

#### Streaks

**Functional Requirements:**

- A daily reading streak counter increments when the user completes at least one reading session per calendar day.
- The streak resets to zero if a full calendar day passes without a session.
- The current streak and longest streak are displayed on the home screen banner.
- A streak freeze feature allows users to preserve their streak for 1 missed day (limit: 2 per month).

#### XP & Leveling

**Functional Requirements:**

- Users earn XP for completing reading sessions. The base XP model is:
  - Session completion: +5 XP
  - Journal reflection written: +5 XP
  - Session note added: +5 XP
  - Mood tags selected: +5 XP
  - Quote saved: +5 XP
- XP accumulates toward levels. Level thresholds increase progressively.
- Levels have themed titles: Casual Reader → Page Turner → Bookworm → Scholar → Sage → Grandmaster.
- A level progress bar shows current XP and XP needed for the next level.

#### Stats Dashboard

**Functional Requirements:**

- Weekly bar chart showing minutes read per day for the current week.
- 28-day activity heatmap (GitHub-style grid) showing reading activity density.
- Personal bests section displaying: longest session, biggest reading week, fastest book completion, and longest streak.
- Reading vibe profile showing the user's most-selected mood tags as a percentage breakdown.
- Insight text generated from mood data (e.g., "You tend to pick up intense reads on weekdays and cozy ones on weekends").

**Acceptance Criteria:**

- Stats update within 5 seconds of a session being saved.
- Heatmap accurately reflects the past 28 days of activity.
- XP calculations are consistent and correct across all bonus categories.

---

### 7. Home Screen

**Priority:** P0 (Must Have)

**Description:** The primary landing screen providing an at-a-glance overview of the user's reading life.

**Functional Requirements:**

- Greeting text with contextual time-of-day awareness ("Good morning/afternoon/evening").
- Weekly reading time summary (e.g., "You've read 3h 12m this week").
- Streak banner with current streak count, flame animation, and longest streak reference.
- Currently Reading section showing up to 5 books with progress bars and note counts.
- Tapping a book navigates to the Timer screen with that book pre-selected.
- Quick stats row showing: total books this year, total hours read, and total notes captured.

---

## Non-Functional Requirements

### Performance

- App cold launch time must be under 2 seconds on iPhone 12 and newer.
- All screen transitions must complete within 300ms.
- Local database queries must return within 100ms.

### Data & Storage

- All user data is stored locally on-device using Core Data or SwiftData.
- Future consideration: optional iCloud sync for multi-device support (not required for v1).
- Data export: users can export their notes and quotes as a JSON or PDF file.

### Platform

- iOS 17.0 minimum deployment target.
- iPhone only for v1 (iPad support deferred to v2).
- Dark mode is the default and only theme for v1.

### Accessibility

- All interactive elements must have minimum 44x44pt tap targets.
- VoiceOver support for all screens and interactive elements.
- Dynamic Type support for body text and note content.
- Color choices must meet WCAG 2.1 AA contrast ratios.

### Privacy

- No user data is transmitted off-device in v1.
- No account creation or login required.
- No analytics or tracking SDKs in v1.

---

## Information Architecture

```
PageFlow
├── Home
│   ├── Greeting + Weekly Summary
│   ├── Streak Banner
│   ├── Currently Reading (book cards)
│   └── Quick Stats Row
├── Timer
│   ├── Book Selector
│   ├── Timer Presets (15/25/30/45m + custom)
│   ├── Circular Timer Display
│   └── Post-Session Journal Flow
│       ├── Step 1: Mood & Reflection
│       ├── Step 2: Session Notes
│       └── Step 3: Quote & Save
├── Notes
│   ├── Search Bar
│   ├── Book Filter Pills
│   └── Expandable Note Cards
├── Quotes
│   ├── Search Bar
│   ├── Quote Cards (with share)
│   └── Random Quote Button
└── Stats
    ├── Level & XP Card
    ├── Weekly Bar Chart
    ├── 28-Day Heatmap
    ├── Personal Bests
    └── Reading Vibe Profile
```

---

## Tech Stack Recommendations

- **Language:** Swift
- **UI Framework:** SwiftUI
- **Local Database:** SwiftData (or Core Data for broader compatibility)
- **Book Search API:** Google Books API or Open Library API
- **Charts:** Swift Charts (iOS 16+)
- **Notifications:** UserNotifications framework
- **Image Generation (share cards):** Core Graphics / UIGraphicsImageRenderer

---

## Success Metrics

- **Retention:** 40% of users return to log a session within 7 days of first use.
- **Session Completion:** 70% of started timer sessions result in a completed post-session journal (at least 1 of 3 steps filled).
- **Notes Adoption:** 50% of sessions include at least one note by week 4.
- **Streak Engagement:** Average active user maintains a streak of 5+ days within the first month.

---

## Future Considerations (v2+)

- iCloud sync and multi-device support.
- iPad and macOS companion apps.
- Social features: share monthly reading wrap-ups, follow friends, book clubs.
- AI-powered note summaries: auto-generate a book summary from all session notes when a book is marked complete.
- Reading goals: yearly book count targets, monthly page goals, genre diversity challenges.
- Barcode scanner for adding physical books.
- Widget support for home screen streak display and quick session start.
- Apple Watch companion for timer control and session logging.
- Spaced repetition: resurface old notes at intervals to reinforce retention.
