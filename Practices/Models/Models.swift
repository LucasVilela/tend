import Foundation
import SwiftData

// Enums are stored as their raw strings and exposed through computed properties.
// This keeps the store simple and avoids SwiftData quirks with enum attributes.

/// Journaling done outside the app.
@Model final class JournalLog {
    var loggedAt: Date = Date.now
    var moodRaw: String?
    /// 30 means "30+".
    var minutes: Int?
    /// Created by a one-tap check-off on Today. Only these are removed by undo.
    var isQuickCheck: Bool = false

    var mood: MoodKind? {
        get { moodRaw.flatMap(MoodKind.init(rawValue:)) }
        set { moodRaw = newValue?.rawValue }
    }

    init(loggedAt: Date, mood: MoodKind? = nil, minutes: Int? = nil, isQuickCheck: Bool = false) {
        self.loggedAt = loggedAt
        self.moodRaw = mood?.rawValue
        self.minutes = minutes
        self.isQuickCheck = isQuickCheck
    }
}

/// A question template for the guided journal.
@Model final class GuidedTemplate {
    var name: String = ""
    /// e.g. "end the day".
    var subtitle: String = ""
    var questions: [String] = []
    var isBuiltIn: Bool = false
    var sortOrder: Int = 0

    init(name: String, subtitle: String, questions: [String], isBuiltIn: Bool, sortOrder: Int) {
        self.name = name
        self.subtitle = subtitle
        self.questions = questions
        self.isBuiltIn = isBuiltIn
        self.sortOrder = sortOrder
    }
}

/// A completed guided template (answered in the app).
@Model final class GuidedEntry {
    var createdAt: Date = Date.now
    /// Snapshot, so renaming a template doesn't change history.
    var templateName: String = ""
    @Relationship(deleteRule: .cascade, inverse: \GuidedAnswer.entry)
    var answers: [GuidedAnswer] = []

    init(createdAt: Date, templateName: String) {
        self.createdAt = createdAt
        self.templateName = templateName
    }

    var orderedAnswers: [GuidedAnswer] { answers.sorted { $0.order < $1.order } }
}

@Model final class GuidedAnswer {
    var order: Int = 0
    /// Snapshot of the question text.
    var question: String = ""
    var answer: String = ""
    var entry: GuidedEntry?

    init(order: Int, question: String, answer: String) {
        self.order = order
        self.question = question
        self.answer = answer
    }
}

/// Meditation done outside the app.
@Model final class MeditationLog {
    var loggedAt: Date = Date.now
    /// 30 means "30+".
    var minutes: Int = 15
    var kindRaw: String?

    var kind: MeditationKind? {
        get { kindRaw.flatMap(MeditationKind.init(rawValue:)) }
        set { kindRaw = newValue?.rawValue }
    }

    init(loggedAt: Date, minutes: Int, kind: MeditationKind? = nil) {
        self.loggedAt = loggedAt
        self.minutes = minutes
        self.kindRaw = kind?.rawValue
    }
}

@Model final class Workout {
    var startedAt: Date = Date.now
    var title: String = ""
    var typeRaw: String = WorkoutType.run.rawValue
    var durationMinutes: Int = 30
    var intensityRaw: String = Intensity.moderate.rawValue
    var distanceKm: Double?
    var notes: String = ""

    var type: WorkoutType {
        get { WorkoutType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    var intensity: Intensity {
        get { Intensity(rawValue: intensityRaw) ?? .moderate }
        set { intensityRaw = newValue.rawValue }
    }

    init(startedAt: Date, title: String, type: WorkoutType, durationMinutes: Int,
         intensity: Intensity, distanceKm: Double? = nil, notes: String = "") {
        self.startedAt = startedAt
        self.title = title
        self.typeRaw = type.rawValue
        self.durationMinutes = durationMinutes
        self.intensityRaw = intensity.rawValue
        self.distanceKm = distanceKm
        self.notes = notes
    }
}

/// A mood check-in: 1 to 3 moods, in the order picked.
@Model final class MoodLog {
    var loggedAt: Date = Date.now
    var moodRaws: [String] = []
    var note: String?

    var moods: [MoodKind] {
        get { moodRaws.compactMap(MoodKind.init(rawValue:)) }
        set { moodRaws = Array(newValue.prefix(Tokens.MoodFace.maxMoodsPerCheckIn)).map(\.rawValue) }
    }

    init(loggedAt: Date, moods: [MoodKind], note: String? = nil) {
        self.loggedAt = loggedAt
        self.moodRaws = Array(moods.prefix(Tokens.MoodFace.maxMoodsPerCheckIn)).map(\.rawValue)
        self.note = note
    }
}

/// Vision board tile. Look-and-remember only: no tracking fields.
@Model final class VisionTile {
    /// Stable identity for drag-to-reorder.
    var uid: UUID = UUID()
    var kindRaw: String = TileKind.text.rawValue
    /// 0 or 1.
    var column: Int = 0
    var order: Int = 0
    var createdAt: Date = Date.now
    // Image
    @Attribute(.externalStorage) var imageData: Data?
    /// 0 small, 1 medium, 2 tall.
    var heightClass: Int?
    var caption: String?
    var subtitle: String?
    // Text
    var text: String?
    var textLabelRaw: String?
    /// Goal only; shown as "GOAL · MAY".
    var dueMonth: Date?
    /// Goal only; rotates sage, lavender, sand, sky.
    var accentIndex: Int?

    var kind: TileKind {
        get { TileKind(rawValue: kindRaw) ?? .text }
        set { kindRaw = newValue.rawValue }
    }

    var textLabel: TextLabel? {
        get { textLabelRaw.flatMap(TextLabel.init(rawValue:)) }
        set { textLabelRaw = newValue?.rawValue }
    }

    init(kind: TileKind, column: Int, order: Int, createdAt: Date = .now) {
        self.kindRaw = kind.rawValue
        self.column = column
        self.order = order
        self.createdAt = createdAt
    }
}

/// One-tap check-off for meditation and exercise when no detailed log exists.
@Model final class DailyCheck {
    /// Start of the local day.
    var day: Date = Date.now
    var practiceRaw: String = Practice.meditation.rawValue
    var checkedAt: Date = Date.now

    var practice: Practice {
        get { Practice(rawValue: practiceRaw) ?? .meditation }
        set { practiceRaw = newValue.rawValue }
    }

    init(day: Date, practice: Practice, checkedAt: Date) {
        self.day = day
        self.practiceRaw = practice.rawValue
        self.checkedAt = checkedAt
    }
}

enum AppSchema {
    static let models: [any PersistentModel.Type] = [
        JournalLog.self, GuidedTemplate.self, GuidedEntry.self, GuidedAnswer.self,
        MeditationLog.self, Workout.self, MoodLog.self, VisionTile.self, DailyCheck.self,
    ]

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(models)
        if !inMemory {
            // Create Application Support up front; otherwise Core Data logs a wall of errors on first launch.
            try FileManager.default.createDirectory(at: .applicationSupportDirectory, withIntermediateDirectories: true)
        }
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
