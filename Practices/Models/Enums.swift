import Foundation

enum Practice: String, Codable, CaseIterable, Identifiable, Sendable {
    case journal, meditation, exercise

    var id: String { rawValue }

    var name: String {
        switch self {
        case .journal: "Journal"
        case .meditation: "Meditation"
        case .exercise: "Exercise"
        }
    }

    /// How the practice reads in a sentence ("days you skipped exercise").
    var activityNoun: String {
        switch self {
        case .journal: "journaling"
        case .meditation: "meditation"
        case .exercise: "exercise"
        }
    }
}

/// The 12 moods, in picker order.
enum MoodKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case happy, calm, excited, grateful, bleh, badSleep, anxious, stressed, sad, lonely, angry, mad

    var id: String { rawValue }

    /// Asset and colour key, as in design/mood-faces.
    var assetName: String { self == .badSleep ? "badsleep" : rawValue }

    var name: String {
        switch self {
        case .happy: "Happy"
        case .calm: "Calm"
        case .excited: "Excited"
        case .grateful: "Grateful"
        case .bleh: "Bleh"
        case .badSleep: "Bad sleep"
        case .anxious: "Anxious"
        case .stressed: "Stressed"
        case .sad: "Sad"
        case .lonely: "Lonely"
        case .angry: "Angry"
        case .mad: "Mad"
        }
    }

    /// Pleasant moods; used to phrase pattern lines ("Calm tends to follow your meditation days").
    var isPleasant: Bool {
        switch self {
        case .happy, .calm, .excited, .grateful: true
        default: false
        }
    }
}

enum MeditationKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case breath, bodyScan, lovingKindness, unguided, other

    var id: String { rawValue }

    /// Label on the Kind chips.
    var chipLabel: String {
        switch self {
        case .breath: "Breath"
        case .bodyScan: "Body scan"
        case .lovingKindness: "Loving-kindness"
        case .unguided: "Unguided"
        case .other: "Other"
        }
    }

    /// Label in session lists.
    var listLabel: String { self == .breath ? "Breath focus" : chipLabel }
}

enum WorkoutType: String, Codable, CaseIterable, Identifiable, Sendable {
    case run, walk, strength, yoga, cycle, other

    var id: String { rawValue }

    var name: String {
        switch self {
        case .run: "Run"
        case .walk: "Walk"
        case .strength: "Strength"
        case .yoga: "Yoga"
        case .cycle: "Cycle"
        case .other: "Other"
        }
    }

    var hasDistance: Bool { self == .run || self == .walk || self == .cycle }
}

enum Intensity: String, Codable, CaseIterable, Identifiable, Sendable {
    case easy, moderate, hard

    var id: String { rawValue }

    var name: String {
        switch self {
        case .easy: "Easy"
        case .moderate: "Moderate"
        case .hard: "Hard"
        }
    }
}

enum TileKind: String, Codable, Sendable { case image, text }

enum TextLabel: String, Codable, CaseIterable, Identifiable, Sendable {
    case goal, mantra, wordsForTheYear, quote, reminder

    var id: String { rawValue }

    var name: String {
        switch self {
        case .goal: "Goal"
        case .mantra: "Mantra"
        case .wordsForTheYear: "Words for the year"
        case .quote: "Quote"
        case .reminder: "Reminder"
        }
    }
}
