# Start here: building the app with Claude Code

This folder holds everything Claude Code needs: `README.md` (what the app does), the screen designs (`design/`), a full spec, and `CLAUDE.md`, which Claude Code reads automatically.

## 1. Create the Xcode project (2 minutes)
In Xcode: **File › New › Project › iOS › App**
- Product Name: anything for now (the app is called Tend)
- Interface: **SwiftUI** · Storage: **SwiftData**
- Save it **inside this folder**.

(Or skip this step and ask Claude Code to set the project up with XcodeGen.)

## 2. Open Claude Code here
```bash
cd ~/Developer/journal-meditation-exercise
claude
```

## 3. Paste this prompt
```
Read README.md (what the app does), CLAUDE.md and design/SPEC.md, and look at every image in design/screenshots and design/mood-faces.
Then build this iPhone app in SwiftUI + SwiftData inside the Xcode project in this folder.

Work in milestones and build with xcodebuild after each one:
1. Theme from design/tokens.json, the SwiftData models, seeding the built-in guided templates, and the 12 mood faces in the asset catalog with a MoodFace view.
2. DayStatsService and MoodStatsService (day status, check-offs, streaks, dominant mood, quick faces, pattern line) with unit tests.
3. Tab bar plus the Today screen: check-off rows, the mood row with 4 quick faces, and the three blob buddies (wobble, liquid fill, faces, tap bounce, confetti).
4. Mood screen (the dominant-mood face from the last 5 check-ins, the 12-face picker with up to 3 picks, note, pattern line, check-ins).
5. Journal: Tracker / Guided switch, tracker (streak, month dots, check-ins), the Log journaling sheet, guided templates, Answer a template, and expandable stored answers.
6. Meditation tracker and the Log meditation sheet (no timer).
7. Exercise and Log workout.
8. Insights, opened from the chart button on Today (month calendar with mini circles, monthly rows, the Mood row).
9. Vision tab: a look-and-remember masonry board of image and text tiles (no tracking), edit mode, and the Add to board sheet (PhotosPicker, text labels incl. Goal with an optional month).

Match the screenshots closely. Use the sample data only in previews.
Before you start, tell me your plan and any questions.
```

## Tips
- To focus on one screen, say: "Compare the Today screen with design/screenshots/01-today.png and fix the differences."
- Open `design/screens/today.html` in a browser to see a screen's design (links between screens work).
- The live design canvas is on claude.ai. If the design changes, ask Claude (Cowork) to refresh this folder.
