# PageFlow

A gamified iOS book tracking app that transforms reading into a rewarding, reflective habit. Track reading sessions with a customizable timer, capture learnings through guided prompts, save quotes, tag moods, and monitor progress through streaks, XP, and detailed stats.

## Overview

PageFlow sits at the intersection of a reading tracker, a personal knowledge base, and a habit-building tool. Every reading session becomes a building block — tracked, reflected on, and stored. By the time you finish a book, you have a personal journal of ideas, moods, and quotes without ever sitting down to write a book summary.

## Features

**Book Library** — Add and manage books manually or via Open Library search. Track status (Want to Read, Currently Reading, Completed, Abandoned) and monitor progress with visual indicators.

**Reading Timer** — Countdown timer with presets (15, 25, 30, 45 min) or custom duration. Runs in the background with local notifications on completion. Pause, resume, or end early.

**Post-Session Journal** — A guided 3-step flow after each session:
1. **Mood & Reflection** — Tag your reading vibe (cozy, intense, reflective, etc.) and respond to rotating reflection prompts.
2. **Session Notes** — Capture key ideas with titles, tags, and chapter references.
3. **Quote & Save** — Save memorable passages and review your session summary.

**Notes Library** — Searchable, filterable collection of all session notes across books. Expandable cards with tag chips and full-text search.

**Quotes Vault** — Browse saved quotes, share as styled image cards, or surface a random quote from your collection.

**Stats & Gamification** — Earn XP for session completion, reflections, notes, mood tags, and quotes. Level up from Casual Reader to Grandmaster. Track daily reading streaks with optional streak freezes. View weekly bar charts, a 28-day activity heatmap, personal bests, and a reading vibe profile.

## Tech Stack

- **Language:** Swift
- **UI Framework:** SwiftUI
- **Local Database:** SwiftData (offline-first)
- **Backend:** Firebase (Authentication, Cloud Firestore)
- **Auth:** Sign in with Apple and email/password via Firebase Auth
- **Book Search:** Open Library API
- **Charts:** Swift Charts
- **Notifications:** UserNotifications
- **Dependencies:** Managed via SPM

## Architecture

PageFlow uses an **offline-first** data architecture. SwiftData is the primary local store — all writes go to SwiftData first, then sync to Cloud Firestore in the background. This ensures the app works fully offline and syncs when connectivity is available.

```
PageFlow/
├── App/
│   ├── PageFlowApp.swift          # Entry point and ModelContainer
│   └── ContentView.swift          # Auth gate + TabView
├── Models/
│   ├── Book.swift
│   ├── ReadingSession.swift
│   ├── SessionNote.swift
│   ├── Quote.swift
│   └── UserStats.swift
├── Views/
│   ├── Auth/AuthView.swift
│   ├── Home/HomeView.swift
│   ├── Timer/TimerView.swift
│   ├── Notes/NotesView.swift
│   ├── Quotes/QuotesView.swift
│   └── Stats/StatsView.swift
├── Services/
│   └── Firebase/
│       ├── FirebaseManager.swift   # Firebase configuration guard
│       ├── AuthService.swift       # Firebase Auth session + sign in
│       └── SyncService.swift       # SwiftData to Firestore sync
├── Components/
└── Utilities/
    ├── Theme.swift                 # Dark mode color palette
    └── Constants.swift             # Enums, XP values, prompts
```

## Getting Started

### Prerequisites

- Xcode 16+ with iOS 17 SDK
- A [Firebase](https://firebase.google.com) project with Authentication and Cloud Firestore enabled
- An Apple Developer account (for Sign in with Apple)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/PageFlow.git
   cd PageFlow
   ```

2. **Configure Firebase**

   In the Firebase console, add an Apple app for each bundle ID you run:
   - `com.codewithmihir.BookTrackingApp`
   - `com.codewithmihir.Booktracking`

   Download each app's `GoogleService-Info.plist` and add it to the matching Xcode app target. The iOS app should place it under `BookTrackingApp/BookTrackingApp/`; the macOS app should place it under `PageFlowMac/PageFlowMac/Booktracking/Resources/` and include it in the app target's resources.

   > `GoogleService-Info.plist` is in `.gitignore`. Use `GoogleService-Info.example.plist` only as a shape reference.

3. **Enable Firebase Authentication**

   Enable Email/Password and Apple providers in Firebase Authentication. For Apple sign-in, configure the Apple Developer settings and Firebase Apple provider values for the app bundle IDs.

4. **Create Firestore rules**

   Create a Cloud Firestore database and publish the rules in `firebase-firestore.rules`. The app writes user data under `users/{uid}/...`, and the rules limit access to the signed-in Firebase user.

5. **Open in Xcode** and run on a simulator or device.

### Firestore Collections

| Collection path | Purpose |
|---|---|
| `users/{uid}/books` | User's book library with status and progress |
| `users/{uid}/readingSessions` | Timer sessions with mood tags and reflections |
| `users/{uid}/sessionNotes` | Notes captured during post-session journal |
| `users/{uid}/quotes` | Saved quotes linked to books and sessions |
| `users/{uid}/userStats` | XP, streaks, and leveling data |

Firestore security rules enforce that users can only access their own data.

## XP & Leveling

| Action | XP |
|---|---|
| Complete a session | +5 |
| Write a reflection | +5 |
| Add a session note | +5 |
| Select mood tags | +5 |
| Save a quote | +5 |
| **Max per session** | **25** |

| Level | XP Threshold |
|---|---|
| Casual Reader | 0 |
| Page Turner | 100 |
| Bookworm | 300 |
| Scholar | 600 |
| Sage | 1,000 |
| Grandmaster | 1,500 |

## Implementation Phases

The project follows a 7-phase build plan (see `implementation-plan.md` for full details):

1. **Project Scaffold** — Models, Firebase, Auth, tab navigation ✅
2. **Book Library** — Add/search/manage books, Home screen
3. **Reading Timer** — Countdown timer with background support
4. **Journal Flow & XP** — Post-session guided journal, XP calculation
5. **Notes & Quotes** — Search, filter, share functionality
6. **Stats & Streaks** — Charts, heatmap, streak tracking, leveling
7. **Polish** — Accessibility, animations, sync robustness, data export

## Requirements

- iOS 17.0+
- iPhone (iPad support planned for v2)
- Dark mode only (v1)

## License

This project is private and not currently licensed for redistribution.
