# Project: Journal · Meditation · Exercise (iPhone app)

An iPhone app for three daily practices (journal, meditation, exercise) plus a mood tracker. Today shows the three practices as overlapping blob "buddies" with faces that fill up during the day. They're the one playful element on an otherwise calm, minimal, dark design. The app is called **Tend** (display name; the Xcode target and module are `Practices`).

## Product rules (most important)
- **Tracking, not doing.** Meditation and plain journaling happen outside the app. The app logs when, how long and optional details. There's no meditation timer and no free-writing editor.
- **Guided journal is the exception.** The user answers question templates in the app, and the answers are stored and readable there.
- **Fast tracking.** One tap on Today checks off a practice (a check circle or a buddy) or logs a mood (one of the quick faces). The detailed loggers are optional.
- **Moods are feelings with faces.** 12 moods (Happy, Calm, Excited, Grateful, Bleh, Bad sleep, Anxious, Stressed, Sad, Lonely, Angry, Mad), each with its own face and colour (`design/mood-faces/`). A check-in holds 1–3 moods. No charts or 1–5 scores: the Mood screen shows the face of the dominant mood from the last 5 check-ins (SPEC §7).
- **Vision is a page to look at and remember.** The Vision tab (Insights opens from Today) is a board of image and text tiles (goals, mantras, words for the year, quotes, reminders). Nothing on it is tracked: no progress bars, steps or counts.

## Read first
0. `README.md`: what the app does, in plain language.
1. `design/SPEC.md`: the full spec (principles, screens, data model, rules). This is the source of truth for behaviour.
2. `design/screenshots/*.png`: what each of the 13 screens must look like (the table in SPEC §1 maps them). `design/images/` holds the sample board photos, for previews only.
3. `design/mood-faces/`: the 12 mood faces as SVGs (add to the asset catalog) and `faces.json`.
4. `design/tokens.json`: colours, type scale, spacing and motion.
5. `design/screens/*.html`: static versions with exact sizes and colours in the inline styles.
6. `design/source/*.dc.html`: the design prototypes. Interaction logic is in the `class Component` at the bottom. Reference only.

## Stack and conventions
- SwiftUI, iOS 17+, iPhone, portrait, dark only. SwiftData for storage. No third-party packages.
- Use `@Observable` for view models. Shared UI goes in `Components/`.
- Generate a `Theme` from `design/tokens.json`; no hard-coded hex values in views.
- Font: Geist, bundled per SPEC §2, with the system font as fallback.
- Put rules in `DayStatsService` and `MoodStatsService`, with XCTest coverage (SPEC §7).
- Seed the four built-in guided templates on first launch.
- Sample data is for `#Preview` only, via an in-memory `ModelContainer`.
- Accessibility: VoiceOver labels on icon buttons, mood faces and charts, 44 pt targets, Dynamic Type, and Reduce Motion (SPEC §9).
- After each milestone, build with `xcodebuild` for an iOS Simulator and fix every warning and error.

## Don't
- Add a meditation timer or a free-writing journal editor.
- Add tracking, progress or counts to the Vision board, or turn moods back into a 1–5 scale.
- Add anything in SPEC §10 without asking.
- Change the visual design. If the spec and a screenshot disagree, ask.
