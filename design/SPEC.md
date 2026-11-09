# Journal · Meditation · Exercise — iPhone app spec

An iPhone app built on three daily practices, **Journal**, **Meditation** and **Exercise**, plus a **Mood** tracker. The look is dark, minimal and calm, with one deliberately playful element: the three "buddies" on Today.

The app has no name yet. Use `[APP NAME]` wherever a name is needed (bundle display name, about screen).

## 0. Product principles
- **Tracking, not doing.** Meditation and plain journaling happen elsewhere (another app, a notebook, a timer). The app records *that* they happened: when, how long, plus optional details. There's no meditation timer and no free-writing editor.
- **One exception, the guided journal.** The user can answer question templates inside the app, and those answers are stored and readable in the app.
- **Fast tracking.** Any practice can be checked off for today with one tap on Today, and mood can be logged with one tap. The detailed loggers are optional extras.
- **Moods are feelings, not a score.** There are 12 moods (Happy, Calm, Excited, Grateful, Bleh, Bad sleep, Anxious, Stressed, Sad, Lonely, Angry, Mad), each with its own face and colour. One check-in can hold up to 3 moods.
- **The vision board is for looking, not tracking.** The Vision tab is a personal page of images and words (goals, mantras, quotes, reminders) to look at and remember. Nothing on it is tracked or counted: no progress bars, steps or percentages.

## 1. Sources of truth

| What | Where |
|---|---|
| Visuals (match these closely) | `design/screenshots/*.png` (390 × 844 pt, rendered @2x) |
| Exact layout, sizes, colours, copy | `design/screens/*.html` (static HTML: open in a browser, inline styles hold the numbers) |
| Interaction logic (check-offs, pickers, expanding answers) | `design/source/*.dc.html`: the `class Component` at the bottom of each file. Reference only; these files don't run outside the design tool |
| Tokens | `design/tokens.json` |

The sample data in the screens (dates around Mon 9 Nov 2026, logs, answers) is **for SwiftUI previews only** and must not ship as real data.

| # | Screen | Screenshot | Prototype file |
|---|---|---|---|
| 1 | Today | `01-today.png`, `01b-today-all-lit.png` | `Main.dc.html` |
| 2 | Insights | `02-insights.png` | `Insights.dc.html` |
| 3 | Mood | `03-mood.png`, `03b-mood-picking.png` (two moods picked), `03c-mood-check-ins.png` (scrolled) | `Mood.dc.html` |
| 4 | Journal: Tracker | `04-journal.png` | `Journal.dc.html` |
| 5 | Log journaling | `05-log-journaling.png` | `JournalEntry.dc.html` |
| 6 | Journal: Guided | `06-guided-journal.png` | `GuidedJournal.dc.html` |
| 7 | Answer a template | `07-guided-entry.png` | `GuidedEntry.dc.html` |
| 8 | Meditation tracker | `08-meditation.png` | `Meditation.dc.html` |
| 9 | Log meditation | `09-log-meditation.png` | `MeditationSession.dc.html` |
| 10 | Exercise | `10-exercise.png` | `Exercise.dc.html` |
| 11 | Log workout | `11-log-workout.png` | `LogWorkout.dc.html` |
| 12 | Vision board | `12-vision.png` | `Vision.dc.html` |
| 13 | Add to board | `13-vision-add.png` | `VisionAdd.dc.html` |

`design/images/*.png` are the sample board images used in the screenshots. Use them for previews only.

`design/mood-faces/` holds the 12 mood faces as vector art: `<kind>.svg` (for sizes up to 60 pt) and `<kind>-large.svg` (thinner strokes, for the 168 pt face on Mood), plus `faces.json` with each face's name, colour and raw path data.

## 2. Platform and architecture
- SwiftUI, iOS 17+, iPhone, portrait. Dark appearance only for v1 (`.preferredColorScheme(.dark)`).
- SwiftData for local persistence. No backend and no accounts.
- `@Observable` view models where logic is non-trivial. No third-party dependencies.
- Goals and the user's first name live in `@AppStorage`.

### Font
The design uses **Geist** (SIL Open Font License), available from Google Fonts (fonts.google.com/specimen/Geist) or vercel.com/font. Bundle Geist Light (300), Regular (400) and Medium (500), register them in Info.plist (`UIAppFonts`), and include the OFL licence. Until it's added, fall back to the system font at the same sizes and weights. Use monospaced digits for every number.

## 3. Design tokens (summary, full list in tokens.json)
- Background `#111113`, hairlines `#222226`, tracks and empty states `#2A2A2F`, outlines `#3A3A40`.
- Text: primary `#ECEAE6`, secondary `#A3A1A7`, tertiary `#85838A`.
- Practice colours: Journal **sand** `#D4A373`, Meditation **lavender** `#A9A3D9`, Exercise **sage** `#9CC5A1`, Mood **sky** `#8FBCD9`. Muted bars (below goal): meditation `#5A5770`, exercise `#4F6152`.
- Buddy colours (brighter, Today only): `#F2B482`, `#B9B0F7`, `#A6E0AE`.
- Mood face colours: one per mood (§3c and `color.moodFaces` in tokens.json). Sky `#8FBCD9` stays the Mood screen's accent (Log button, links).
- Text on accent fills: `#111113`.
- Horizontal padding 24, sections 22–28 apart, hit targets at least 44 pt, 1 pt hairlines. No cards, gradients or shadows, except a soft shadow under the floating buttons.

### 3b. Organic style (applies everywhere)
The whole UI borrows the buddies' soft, hand-made feel:
- **No perfect circles or capsules.**
  - Circles (dots, calendar days, the week-strip "today" marker, mood and check buttons) use a blob radius such as `58% 42% 54% 46% / 47% 55% 45% 53%`.
  - Capsules (pills, chips, switches, primary buttons) use an uneven radius such as `26 18 24 16 / 18 25 16 23` pt.
  - Cards (vision tiles) use `20 13 18 12 / 14 19 12 17` pt.
  - In SwiftUI, build these as a reusable `BlobShape` / `OrganicCapsule` `Shape`.
- **Wobble**: floating + buttons and Today's check faces slowly morph between two blob shapes (9 s loop, `blobmorph`), staggered. Turn it off with Reduce Motion.
- **Wavy lines instead of hairlines**: every separator, input underline and the tab bar's top edge is a gentle sine wave (period 24 pt, amplitude about 1.2 pt, 1.2 pt stroke, `#2E2E34`). See `design/images/wave.svg`, which tiles every 96 pt. Build it as a `WaveLine` `Shape`.
- **Faces on buttons**:
  - **Check faces** on Today (34 pt blobs) replace check marks:
    - not started: dashed outline in the practice colour, sleepy face (flat eyes, small mouth)
    - partial: solid outline, meditating face (closed curved eyes, small smile)
    - done: filled with the practice colour, dark happy face
  - **Mood faces**: every mood is shown as its own face (§3c), never as a plain dot or a word alone.

### 3c. Mood faces
Twelve moods, each a blob filled with its colour with a dark (`#1A1A1F`) face on top. The art is in `design/mood-faces/`; in Xcode add the SVGs to the asset catalog (Preserve Vector Data, single scale) and layer them over a `BlobShape` filled with the mood colour. Use `<kind>-large.svg` for the 168 pt face. Extras such as the heart, Zzz, sweat drop, tear and steam may touch the blob's edge; that's intended.

| Kind | Name | Colour | Face |
|---|---|---|---|
| `happy` | Happy | `#F2D27A` | oval dot eyes, wide smile, rosy cheeks |
| `calm` | Calm | `#8FBCD9` | closed down-curved eyes, small smile, soft cheeks |
| `excited` | Excited | `#F29EB4` | upturned arc eyes, big open grin, two sparkles, cheeks |
| `grateful` | Grateful | `#F2B482` | happy arc eyes, gentle smile, cheeks, small red heart top right |
| `bleh` | Bleh | `#ABA98E` | half-lidded eyes, flat tilted mouth |
| `badsleep` | Bad sleep | `#9497C2` | droopy closed eyes with eye bags, little "o" yawn, Zz |
| `anxious` | Anxious | `#8DCBBE` | wide ring eyes with small pupils, worried brows, wobbly mouth, sweat drop |
| `stressed` | Stressed | `#E3A15F` | × eyes, zig-zag mouth |
| `sad` | Sad | `#7F98CC` | sad brows, dot eyes, frown, one tear |
| `lonely` | Lonely | `#C7A0C9` | soft worried brows, small eyes looking down and aside, tiny frown |
| `angry` | Angry | `#E8876C` | slanted brows, dot eyes, frown |
| `mad` | Mad | `#D65A50` | steep brows, slit eyes, gritted teeth, steam |

Sizes: Today row 28 pt, Journal list 24 pt, check-in rows 30 pt, Log journaling row 38 pt, Mood picker 44 pt, Mood hero 168 pt. Selected state: a 2 pt ring in the face colour with a 2.5 pt gap (background colour), scale 1.08–1.12, label in primary.

## 4. Navigation
- `TabView` with 5 tabs: **Today**, **Journal**, **Meditate**, **Exercise**, **Vision** (a masonry-grid icon). Use a custom tab bar: icon over an 11 pt label, active tab in primary, inactive in tertiary, hairline on top.
- **Insights** isn't a tab. It's pushed (back button `‹ Today`) from the chart icon button at the top right of Today.
- **Mood** is pushed (back button `‹ Today`) from Today's Mood row (its name or the dashed + face) or Insights' Mood row.
- The **Journal** tab has a Tracker / Guided capsule switch at the top (screens 4 and 6).
- Sheets (`fullScreenCover`):
  - Journal Tracker + → **Log journaling**
  - Guided template row → **Answer a template**
  - Meditate + → **Log meditation**
  - Exercise + → **Log workout**
  - Vision + → **Add to board**

## 5. Screens

### 5.1 Today
- Date (14 pt tertiary) and greeting `Good evening, Lucas` (28 pt light): morning before 12:00, afternoon before 18:00, evening after that. Top right: a 44 pt chart icon button (label "Insights") that opens Insights.
- **Week strip**: the rolling last 7 days. Each day has its weekday initial, the date, and three 4 pt dots (journal, meditation, exercise): full colour = done, 45 % = partial, track colour = none. Today's date sits in a 34 pt filled circle.
- **The three buddies**: three 128 pt blobs overlapping like a Venn diagram in a 240 × 228 pt area. Journal is at (10, 12), Meditation at (102, 12) and Exercise at (66, 92), each the blob's top-left corner.
  - Blend mode is screen, so overlaps glow.
  - **Wobble**: the outline morphs between organic shapes on a 9 s loop.
  - **Bob**: 6 pt up and down, about 5.4–6.1 s, staggered.
  - **Liquid fill** to today's progress, with a scrolling sine-wave surface (period 64, amplitude about 5, 3.4 s per loop) and a springy level change.
  - **Outline**: 2 pt, solid once started, dashed while empty.
  - **Faces** in the non-overlapping part of each blob:
    - full = happy (blinking eyes, smile, rosy cheeks)
    - partial = meditating (closed eyes)
    - empty = sleepy (flat eyes, "o" mouth, floating z's)
  - **Tap a buddy** = fast check-off: a squash-and-stretch bounce (0.7 s), a light haptic, and the liquid springs to full. Tap again to undo a manual check-off. Long-press opens the detailed logger.
  - **All three full**: the centre sparkle (dim `#4A4852` until then) becomes a 28 pt twinkling gold star (`#FFBE3D`) with a 16-piece confetti burst and a success haptic.
  - **Reduce Motion**: no wobble, bob, waves, blink, z's, twinkle or confetti.
- Summary line: `1 of 3 complete · tap to check off` (the count in primary). When all three are done: `3 of 3 lit. Party in the middle!`
- **Check-off rows** (hairlines, 58 pt):
  - Journal, Meditation and Exercise: name over status (`Done · 7:12 am`, `10 of 15 min`, `0 of 30 min`), with a 30 pt check circle on the right (48 pt hit area).
    - Check circle states: outline at 45 % (not started), full-colour outline (partial), filled with a dark check (done).
    - Tapping the circle toggles today's check-off and animates the matching buddy. Tapping the name opens the practice's tab.
  - **Mood row**: `Mood` over the last mood and its time (`Calm · 1:15 pm`, or `How are you feeling?` if none today). On the right, four **quick faces** (28 pt, 40 × 48 pt hit areas) and a dashed + blob that opens Mood with all 12.
    - Quick faces are the user's 4 most-used moods over the last 30 days, padded with Happy, Calm, Anxious, Bleh (the screenshot shows those defaults).
    - Tapping one logs a single-mood check-in **immediately**: it gets the selection ring and grows, the others dim to 60 %, and the status reads `Calm · just now`. Tapping it again removes that check-in. Tapping the name opens Mood.

### 5.2 Insights
- `‹ Today` back button, then the title. While it's open, the tab bar shows Today as active.
- Month header with previous/next.
- Monday-first calendar with a mini three-circle mark per active day (11 pt circles; done = 35 % fill, partial = stroke, none = `#2E2E33`).
- Rows with 2 pt progress lines for Journal (`8 of 9 days · 4-day streak`), Meditation (`7 of 9 days · 2h 05m`) and Exercise (`5 of 9 days · 3h 10m`).
- A **Mood** row (`Mostly Calm · 17 check-ins`, the most frequent mood this month) that opens Mood.

### 5.3 Mood (no chart; a face instead)
- `‹ Today` back button and the title `Mood`.
- **Lately face**: the face of the **dominant recent mood** at 168 pt (`<kind>-large.svg` on a blob in that mood's colour, with a soft glow of the same colour at 25 % opacity, 64 pt blur).
  - Dominant mood = a weighted count over the **last 5 check-ins**, weights 5, 4, 3, 2, 1 with the newest heaviest; every mood in a check-in gets that check-in's weight; ties go to the most recent (§7).
  - It wobbles and bobs like the buddies. When a new check-in changes it, it does the squash bounce and the colour crossfades over 0.6 s.
  - VoiceOver label: "Lately you're mostly Calm, with some Anxious".
- Under the face: `Lately you're mostly` (14 tertiary), the mood name (32 pt light, in the mood's colour), `with some Anxious` (15 secondary, the name in its colour) when the runner-up scores at least 3, and `From your last 5 check-ins · the newest count most` (12 tertiary).
- **How are you feeling?** with `Pick up to 3` on the right (it becomes `2 of 3`). A 4 × 3 grid of 44 pt faces with 12 pt labels, in this order: Happy, Calm, Excited, Grateful / Bleh, Bad sleep, Anxious, Stressed / Sad, Lonely, Angry, Mad.
  - Tap to select or deselect (ring, scale 1.08, label in primary). With 3 selected, the rest dim to 35 % and can't be picked.
  - Once something is selected, an underlined `Add a note (optional)` field and a sky button `✓ Log Calm + Grateful` appear (see `03b-mood-picking.png`). Logging adds the check-in to the top of Check-ins, clears the picker and recalculates the face.
- **Pattern line** (15/22 secondary, mood names in their colours): one or two short observations from the last 14 days linking moods to practices, e.g. `Anxious showed up twice this week, both on days you skipped exercise. Calm tends to follow your meditation days.` Only state a pattern when a mood appears at least twice and every one of those days shares the same practice condition. Hide the line when nothing qualifies.
- **Check-ins**: newest first. Each row shows the mood names joined with ` + ` (`Anxious + Bad sleep`), then `Today · 7:30 am · Slept badly` (the note is optional), with the faces on the right (30 pt, overlapping by 10 pt, each with a 2.5 pt background-colour outline). Swipe to delete.

### 5.4 Journal: Tracker
- Title, the Tracker / Guided switch (44 pt capsule segments, selected segment `#26262A`), and `Once a day · journaled today at 7:12 am`.
- Streak (56 pt light) with `8 of 9 / days this month`.
- Month dots: filled sand = journaled; `#3A3A40` outline = missed; `#222226` outline = upcoming.
- **Check-ins** list: day, time and optional duration, and the optional mood on the right (its name in its colour plus its 24 pt face). A completed guided entry also counts as that day's journaling.
- Floating sand + → Log journaling.

### 5.5 Log journaling
- `Wrote today? Log it here. Your words stay wherever you keep them.`
- **When** row (date-time picker, backdating allowed).
- **How do you feel?** (optional): a horizontally scrolling row of all 12 faces (38 pt in 64 pt-wide buttons, label under each), in the §5.3 order. Pick one; tap again to clear. The others dim to 50 % while one is picked. If a mood is picked, saving also creates a `MoodLog` with that mood at the same time, so it appears on Mood.
- **How long?** (optional): dots for 5, 10, 15, 20 and 30+ minutes.
- Sand `Log journaling` button.

### 5.6 Journal: Guided
- The same switch, with Guided selected.
- **Templates**: hairline rows with the name and `4 questions · end the day`. Tapping one opens Answer a template. Built-in templates:
  - **Morning intention**: How do I want to feel today? / What matters most today? / One kind thing I can do
  - **Evening reflection**: What went well today? / What was hard? / What did I learn? / One thing for tomorrow?
  - **Gratitude**: Three things I'm grateful for / Someone who helped me lately / A small pleasure from today
  - **Weekly review** (suggested Sundays): What went well this week? / What drained me? / What did I learn about myself? / What will I focus on next week? / How did I take care of myself?
- **Your answers**: past guided entries, newest first (sand dot, template name, date and time). Tapping a row expands it in place to show every question (13 pt tertiary) with its stored answer (15/22 primary). The chevron rotates. Only one entry is open at a time. Long-press offers Edit and Delete.

### 5.7 Answer a template
- Close (confirm if anything is typed), date and time in the centre, the template name as a 28 pt light title, and a segmented progress bar with one 3 pt segment per question (sand when answered) and `1 of 4`.
- Each question: number (13 pt sand), question text (18 pt light), and an underlined multi-line answer field (16/24) whose underline turns sand when focused.
- Sand `Save answers` button. It saves even if some answers are empty, but not if all are; empty answers are skipped when reading back.
- Saving creates a `GuidedEntry`, which also counts as journaling that day.

### 5.8 Meditation tracker
- Title and `15 minutes a day · 5-day streak`.
- Big number (minutes in the last 7 days).
- Bar chart: bars meet the goal = lavender, below = muted, with a dashed goal line.
- `Recent sessions` (kind, date and time, minutes).
- Floating lavender + → Log meditation.

### 5.9 Log meditation
- `Sat today? Log it here. Use whatever app or timer you like.`
- **When** row.
- **How long?**: dots for 5, 10, 15, 20 and 30+ minutes, default 15.
- **Kind** (optional): chips for Breath, Body scan, Loving-kindness, Unguided and Other.
- Lavender button labelled with the duration, e.g. `Log 15 minutes`.

### 5.10 Exercise
- Title, goal and streak.
- `Last 7 days` stats: active time, workouts and km.
- Bar chart in sage with a 30 min goal line.
- `Recent workouts` list.
- Floating sage + → Log workout.

### 5.11 Log workout
- Type chips: Run, Walk, Strength, Yoga, Cycle, Other.
- Duration stepper: 5–300 in steps of 5, default 30.
- Intensity segmented control: Easy, Moderate, Hard.
- Distance in km, only for Run, Walk and Cycle.
- Notes field.
- Sage `Save workout` button.

### 5.12 Vision board
A page to **look at and remember**. Nothing here is tracked: no progress bars, step counters, percentages or tick buttons.
- Title `Vision`, the line `A page to look at and remember`, and an `Edit` / `Done` text button at the top right.
- **Board**: two columns (10 pt gap) of tiles in a masonry layout. Each new tile goes into the shorter column; in edit mode, long-press and drag to reorder. Tiles have organic 16 pt corners and a `#18181C` background. Two kinds:
  - **Image**: the user's photo, aspect-fill, at its chosen height (small 116, medium 140, tall 200–250 pt). An optional caption (14/500 white) and subtitle (12, `#DAD8D3`) sit over a bottom scrim (`rgba(10,10,12,0.8)` → transparent, for legibility).
  - **Text**: a small uppercase label (11 pt, medium, tracking 0.08) over light text (20/26 pt, 300). Labels and their look:
    - `GOAL` (or `GOAL · MAY` when it has a month): label in an accent colour, text in primary. Just a statement, e.g. `Run a half marathon`.
    - `MANTRA`: tertiary label, text in sand.
    - `WORDS FOR THE YEAR`: tertiary label, primary text.
    - `QUOTE`: tertiary label, lavender text in curly quotes.
    - `REMINDER`: sky label, primary text.
    - Goal accents rotate sage, lavender, sand, sky in creation order.
- **Edit mode**: tiles get a 1 pt dashed `#3A3A40` outline and a remove (×) button with a 44 pt hit area. Removing a tile asks for confirmation.
- Tapping a tile (outside edit mode) opens it in the Add to board sheet, pre-filled, to edit.
- Floating 56 pt `#ECEAE6` + button → Add to board.

### 5.13 Add to board
- A capsule switch for **Image | Text**.
- **Image**: a 240 pt dashed drop zone (`Choose a photo` / `From Photos or Files`) that opens `PhotosPicker`, then crop to the chosen tile size. Plus an optional caption field.
- **Text** (default):
  - **Label** chips: Goal, Mantra, Words for the year, Quote, Reminder (default Goal).
  - **Text** field (22 pt light, multi-line). The placeholder follows the label: `Something you want to do`, `A line to come back to`, `e.g. Steady · Present · Kind`, `Words that move you`, `Something to remember`.
  - **By when** row, only for Goal: `Optional · just a date to keep in mind`, month and year picker (`May 2027`). It only changes the label to `GOAL · MAY`; nothing counts down or tracks.
  - **On your board**: a live, half-width preview of the tile.
- A full-width `#ECEAE6` `Add to board` button.

## 6. Data model (SwiftData)

```swift
enum Practice: String, Codable, CaseIterable { case journal, meditation, exercise }
enum MoodKind: String, Codable, CaseIterable {
    case happy, calm, excited, grateful, bleh, badSleep, anxious, stressed, sad, lonely, angry, mad
    // order = picker order; asset names: happy, calm, excited, grateful, bleh, badsleep, anxious, stressed, sad, lonely, angry, mad
}
enum MeditationKind: String, Codable, CaseIterable { case breath, bodyScan, lovingKindness, unguided, other }
enum WorkoutType: String, Codable, CaseIterable { case run, walk, strength, yoga, cycle, other }
enum Intensity: String, Codable, CaseIterable { case easy, moderate, hard }

/// Journaling done outside the app.
@Model final class JournalLog {
    var loggedAt: Date
    var mood: MoodKind?               // also written as a MoodLog
    var minutes: Int?                 // 30 means "30+"
}

/// Guided journal (answered in the app).
@Model final class GuidedTemplate {
    var name: String
    var subtitle: String              // e.g. "end the day"
    var questions: [String]
    var isBuiltIn: Bool
    var sortOrder: Int
}

@Model final class GuidedEntry {
    var createdAt: Date
    var templateName: String          // snapshot, so renaming a template doesn't change history
    @Relationship(deleteRule: .cascade) var answers: [GuidedAnswer]
}

@Model final class GuidedAnswer {
    var order: Int
    var question: String              // snapshot of the question text
    var answer: String
}

/// Meditation done outside the app.
@Model final class MeditationLog {
    var loggedAt: Date
    var minutes: Int                  // 30 means "30+"
    var kind: MeditationKind?
}

@Model final class Workout {
    var startedAt: Date
    var title: String
    var type: WorkoutType
    var durationMinutes: Int
    var intensity: Intensity
    var distanceKm: Double?
    var notes: String
}

@Model final class MoodLog {
    var loggedAt: Date
    var moods: [MoodKind]             // 1 to 3, in the order picked
    var note: String?
}

enum TileKind: String, Codable { case image, text }
enum TextLabel: String, Codable { case goal, mantra, wordsForTheYear, quote, reminder }

/// Vision board tile. Look-and-remember only: no tracking fields.
@Model final class VisionTile {
    var kind: TileKind
    var column: Int                   // 0 or 1
    var order: Int
    var createdAt: Date
    // image
    @Attribute(.externalStorage) var imageData: Data?
    var heightClass: Int?             // 0 small, 1 medium, 2 tall
    var caption: String?
    var subtitle: String?
    // text
    var text: String?
    var textLabel: TextLabel?
    var dueMonth: Date?               // goal only; shown as "GOAL · MAY"
    var accentIndex: Int?             // goal only; rotates sage, lavender, sand, sky
}

/// One-tap check-off for meditation and exercise when no detailed log exists.
@Model final class DailyCheck {
    var day: Date                     // start of the local day
    var practice: Practice
    var checkedAt: Date
}
```

Seed the four built-in `GuidedTemplate`s on first launch.

Settings (`@AppStorage`): `firstName`, `meditationGoalMinutes` (15), `exerciseGoalMinutes` (30).

## 7. Rules
- **Day status** (local calendar day):
  - Journal: done if there's ≥ 1 `JournalLog` **or** ≥ 1 `GuidedEntry`.
  - Meditation: done if logged minutes ≥ goal **or** there's a `DailyCheck`; partial if minutes > 0.
  - Exercise: done if workout minutes ≥ goal **or** there's a `DailyCheck`; partial if minutes > 0.
- **Fast check-off** (Today check circle or buddy tap):
  - Journal: creates a `JournalLog` stamped now; undo deletes that log.
  - Meditation and exercise: create a `DailyCheck`; undo deletes it.
  - Undo never deletes detailed logs.
- **x of 3** = practices done today. Mood isn't part of the count.
- **Streak** = consecutive done days ending today if today is done, otherwise ending yesterday.
- **Mood**:
  - **Dominant mood** (Mood face) over the 5 most recent `MoodLog`s, newest first with weights 5, 4, 3, 2, 1: each mood scores the sum of the weights of the check-ins it appears in. The highest score wins; ties go to the mood that appears most recently. The runner-up is shown as `with some X` if its score is at least 3. With fewer than 5 logs, use what exists with the same weights. With none, show Calm's face dimmed to 40 % and `No check-ins yet`.
    - Example from the screenshots: Calm (5), Anxious + Bad sleep (4), Happy (3), Grateful (2), Anxious (1) → Calm 5, Anxious 5, Bad sleep 4 … → tie, Calm is newer → `Mostly Calm, with some Anxious`.
  - "Mostly X" on Insights = the mood in the most check-ins over the period (ties → most recent).
  - Quick faces on Today = the 4 most-used moods over the last 30 days (padded with Happy, Calm, Anxious, Bleh).
  - Pattern line as in 5.3.
- **Vision**: nothing is tracked. No progress, counts, steps or confetti on the board.
- Weeks start on Monday. "Last 7 days" is rolling and includes today.
- Put all of this in `DayStatsService` and `MoodStatsService` with unit tests.

## 8. Shared components
`BuddyCluster`, `MoodFace(kind:size:selected:)` (blob + SVG face), `MoodHeroFace`, `MoodQuickRow` (Today), `MoodGrid` (4 × 3, up to 3 selected), `MoodScrollRow` (Log journaling), `MoodStack` (overlapping faces in check-in rows), `MiniThreeCircles`, `CheckCircle`, `CheckOffRow`, `MasonryBoard`, `ImageTile`, `TextTile`, `WeekStrip`, `MonthDots`, `CapsuleSwitch`, `ExpandableAnswerRow`, `QuestionField`, `SegmentedProgress`, `HairlineRow`, `MiniBarChart`, `FloatingActionButton`, `DotSelector`, `ChipGroup`, `SegmentedCapsule`, `Stepper`, `UnderlinedField`, plus `Theme` from tokens.json.

## 9. Accessibility
- Label every icon-only button and mood face, e.g. "Log mood: Calm" (Today), "Calm, selected" (pickers), "All moods" (the + face), "Check off exercise for today" / "Exercise done today. Tap to undo.", close, −/+.
- Expandable answer rows use `aria-expanded` semantics (`.accessibilityAddTraits(.isButton)` plus a value of expanded or collapsed).
- Charts and buddies get combined labels. Check-in rows read as one element: "Anxious and Bad sleep, today 7:30 am, slept badly". Mood colours are never the only cue; names are always shown or spoken.
- Support Dynamic Type, 44 pt hit targets and Reduce Motion.

## 10. Out of scope for v1 (ask before adding)
Creating or editing custom templates, custom moods, multiple vision boards, goal tracking or progress on the vision board, sharing or exporting the board as an image, reminders and notifications, HealthKit import or export (mindful minutes, workouts), iCloud sync, search, light mode, iPad.
