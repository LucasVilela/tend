#if DEBUG
import Foundation
import SwiftData

/// The design's sample data, placed relative to today so the screens look like the screenshots
/// (today plays the part of Mon 9 Nov). For `#Preview` and the `-sampleData` debug launch argument only.
@MainActor
enum SampleData {
    static func makeContainer(now: Date = .now) throws -> ModelContainer {
        let container = try AppSchema.makeContainer(inMemory: true)
        try TemplateSeeder.seedIfNeeded(container.mainContext)
        insert(into: container.mainContext, now: now)
        try container.mainContext.save()
        return container
    }

    /// A container for previews; crashes loudly if the schema is broken.
    static var previewContainer: ModelContainer {
        do { return try makeContainer() } catch { fatalError("Preview container: \(error)") }
    }

    static func insert(into context: ModelContext, now: Date = .now) {
        let cal = Calendar.practices
        let today = cal.startOfDay(for: now)
        func at(_ dayOffset: Int, _ hour: Int, _ minute: Int) -> Date {
            let day = cal.date(byAdding: .day, value: dayOffset, to: today)!
            return cal.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
        }

        // Journal: every day of the last 9 except 4 days ago (Thu 5 in the design).
        let journal: [(Int, Int, Int, Int?, MoodKind?)] = [
            (0, 7, 12, 15, .badSleep), (-1, 21, 40, 10, .happy), (-2, 8, 5, 10, nil), (-3, 22, 10, 5, .anxious),
            (-5, 7, 30, 15, nil), (-6, 7, 45, 10, nil), (-7, 8, 0, 20, .calm), (-8, 9, 15, 10, nil),
        ]
        for (d, h, m, minutes, mood) in journal {
            context.insert(JournalLog(loggedAt: at(d, h, m), mood: mood, minutes: minutes))
        }

        let evening = GuidedEntry(createdAt: at(-1, 21, 40), templateName: "Evening reflection")
        context.insert(evening)
        let answers = [
            ("What went well today?", "Cleared the desk and planned the week. Called Mum."),
            ("What was hard?", "Felt sluggish after lunch and skipped my stretch."),
            ("What did I learn?", "A short walk fixes the afternoon slump."),
            ("One thing for tomorrow?", "Start with the hardest task."),
        ]
        for (i, qa) in answers.enumerated() {
            let answer = GuidedAnswer(order: i, question: qa.0, answer: qa.1)
            context.insert(answer)
            answer.entry = evening
        }

        // Meditation: 90 minutes over the last 7 days, nothing 6 days ago, 10 of 15 today.
        let meditation: [(Int, Int, Int, Int, MeditationKind?)] = [
            (0, 6, 40, 10, .breath), (-1, 21, 15, 20, .bodyScan), (-2, 7, 5, 15, .breath),
            (-3, 6, 50, 15, .unguided), (-4, 7, 0, 15, .lovingKindness), (-5, 7, 10, 15, .breath),
            (-7, 7, 20, 20, .bodyScan), (-8, 8, 0, 15, .breath),
        ]
        for (d, h, m, minutes, kind) in meditation {
            context.insert(MeditationLog(loggedAt: at(d, h, m), minutes: minutes, kind: kind))
        }

        // Exercise: 2h 25m, 4 workouts and 11.2 km over the last 7 days.
        let workouts: [(Int, Int, Int, String, WorkoutType, Int, Intensity, Double?)] = [
            (-1, 7, 30, "Easy morning run", .run, 32, .easy, 5.2),
            (-2, 17, 0, "Upper body strength", .strength, 45, .moderate, nil),
            (-4, 18, 0, "Vinyasa flow", .yoga, 30, .easy, nil),
            (-6, 7, 0, "Tempo run", .run, 38, .hard, 6.0),
            (-7, 18, 30, "Leg day", .strength, 45, .hard, nil),
        ]
        for (d, h, m, title, type, minutes, intensity, km) in workouts {
            context.insert(Workout(startedAt: at(d, h, m), title: title, type: type,
                                   durationMinutes: minutes, intensity: intensity, distanceKm: km))
        }

        // Mood check-ins, newest first in the design.
        let moods: [(Int, Int, Int, [MoodKind], String?)] = [
            (0, 13, 15, [.calm], nil),
            (0, 7, 30, [.anxious, .badSleep], "Slept badly"),
            (-1, 21, 0, [.happy], "Dinner with friends"),
            (-2, 18, 0, [.grateful], "Long walk by the water"),
            (-3, 22, 0, [.anxious], "Work stress"),
            (-5, 15, 0, [.bleh], nil),
            (-7, 19, 0, [.calm], nil),
            (-8, 20, 30, [.calm], nil),
        ]
        for (d, h, m, kinds, note) in moods {
            context.insert(MoodLog(loggedAt: at(d, h, m), moods: kinds, note: note))
        }
    }
}
#endif
