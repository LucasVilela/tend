# Tend: what the app does

A calm iPhone app for keeping three daily practices: **Journal**, **Meditation** and **Exercise**. It also has a **mood tracker** and a **vision board**. You do the practices wherever you like (a notebook, a meditation app, a run outside). This app is where you note that you did them, see how your days are going, and keep what matters in view.

The app is dark, minimal and quiet. The one playful touch is a set of blob characters with faces, called "buddies".

## The idea in one minute
- Every day has three practices to check off. One tap on Today marks each one done.
- Three blob buddies on Today, one per practice, fill up as you go. A sleepy face means not started, a calm one means started, and a happy one means done. When all three are full, they throw a little party.
- How you feel is logged with faces, not numbers. Pick from 12 moods, up to 3 at a time. The Mood screen shows a big face for how you've mostly been feeling lately.
- The Vision tab is a personal board of photos and words (goals, a mantra, words for the year, quotes, reminders) that you just look at. Nothing on it is tracked.
- Everything stays on the phone. There are no accounts and no backend.

## What you can do, screen by screen

**Today** (home)
- See your week at a glance as a strip of the last 7 days, with a dot for each practice.
- Tap a buddy or a check circle to mark a practice done. Tap again to undo.
- Log a mood with one tap from four quick faces, or open all 12 with the + button.
- A chart button opens **Insights**: a month calendar and totals for each practice and your mood.

**Journal**
- **Tracker**: you journal elsewhere and log it here, with when, how long and how you felt. It shows your streak, a month of dots and past check-ins.
- **Guided**: answer question templates inside the app (Morning intention, Evening reflection, Gratitude, Weekly review). Your answers are saved and can be read back later. A guided entry also counts as journaling that day.

**Meditate**
- You meditate with any app or timer and log it here, with when, how long and what kind (breath, body scan, loving-kindness…).
- See minutes for the week against a daily goal, plus recent sessions. There's no timer in the app.

**Exercise**
- Log a workout with its type, duration, intensity, distance for runs, walks and rides, and notes.
- See the last 7 days against a daily goal, plus recent workouts.

**Mood**
- 12 moods, each with its own face and colour: Happy, Calm, Excited, Grateful, Bleh, Bad sleep, Anxious, Stressed, Sad, Lonely, Angry and Mad.
- A big face shows your dominant mood from your last 5 check-ins, with the newest counting most (for example "Mostly Calm, with some Anxious").
- Each check-in holds up to 3 moods and an optional note.
- A gentle pattern line links moods to practices, for example "Anxious showed up twice this week, both on days you skipped exercise".

**Vision**
- A two-column board of image tiles and text tiles: Goal (with an optional month), Mantra, Words for the year, Quote and Reminder.
- It's for looking and remembering only, with no progress bars or counters. You can edit, reorder and remove tiles.

## What it deliberately doesn't do
- No meditation timer and no journal writing editor. The only exception is guided-template answers.
- No tracking or progress on the vision board.
- No mood scores, charts or 1–5 scales. Moods are faces.
- In v1: no accounts, sync, notifications, HealthKit, light mode or iPad.

## Where the details are
- `CLAUDE.md`: the rules for Claude Code (read automatically).
- `design/SPEC.md`: the full spec, covering screens, data model and rules.
- `design/screenshots/`: how every screen should look.
- `design/mood-faces/`: the 12 mood faces as SVGs.
- `START_HERE.md`: how to set up Xcode and the prompt to paste into Claude Code.

## Building and running
Requires Xcode 16 or later (iOS 17+ deployment target). No third-party packages.

1. Open `Practices.xcodeproj` and run the **Practices** scheme on an iPhone simulator or device.
2. Run the unit tests with ⌘U, or from Terminal:
   ```bash
   xcodebuild test -project Practices.xcodeproj -scheme Practices -destination 'platform=iOS Simulator,name=iPhone 17'
   ```
3. To see every screen filled with the design's sample data, run `scripts/sim.sh` (it builds, installs and launches on the booted simulator). Debug-only launch arguments open specific screens: `-startTab journal|meditate|exercise|vision`, `-startRoute mood|insights`, `-startLogger journal|meditation|exercise`. Sample data lives in memory only and never touches real data.

The Xcode project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen); the source folders are synced, so new files show up without regenerating. Colours, type and motion come from `design/tokens.json` via `scripts/generate_theme.py`.

## Project layout
- `Practices/` — the app: `Theme/` (generated tokens, organic shapes), `Models/` (SwiftData), `Services/` (day and mood rules), `Components/` (shared UI, buddies, mood faces), `Features/` (one folder per screen).
- `PracticesTests/` — unit tests for the rules in `DayStatsService` and `MoodStatsService`.
- `design/` — the spec, tokens, screenshots, mood-face art and HTML prototypes the app is built from.

## License
The code is released under the [MIT License](LICENSE).
The bundled [Geist](https://github.com/vercel/geist-font) font is licensed separately under the SIL Open Font License (`Practices/Resources/Fonts/Geist-OFL.txt`).
