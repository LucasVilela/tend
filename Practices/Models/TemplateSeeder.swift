import Foundation
import SwiftData

/// Inserts the four built-in guided templates the first time the app runs.
enum TemplateSeeder {
    struct Seed {
        let name: String
        let subtitle: String
        let questions: [String]
    }

    static let builtIn: [Seed] = [
        Seed(name: "Morning intention", subtitle: "start the day", questions: [
            "How do I want to feel today?",
            "What matters most today?",
            "One kind thing I can do",
        ]),
        Seed(name: "Evening reflection", subtitle: "end the day", questions: [
            "What went well today?",
            "What was hard?",
            "What did I learn?",
            "One thing for tomorrow?",
        ]),
        Seed(name: "Gratitude", subtitle: "any time", questions: [
            "Three things I'm grateful for",
            "Someone who helped me lately",
            "A small pleasure from today",
        ]),
        Seed(name: "Weekly review", subtitle: "Sundays", questions: [
            "What went well this week?",
            "What drained me?",
            "What did I learn about myself?",
            "What will I focus on next week?",
            "How did I take care of myself?",
        ]),
    ]

    /// Idempotent: does nothing if built-in templates already exist.
    @discardableResult
    static func seedIfNeeded(_ context: ModelContext) throws -> Int {
        let existing = try context.fetchCount(FetchDescriptor<GuidedTemplate>(predicate: #Predicate { $0.isBuiltIn }))
        guard existing == 0 else { return 0 }
        for (index, seed) in builtIn.enumerated() {
            context.insert(GuidedTemplate(
                name: seed.name, subtitle: seed.subtitle, questions: seed.questions,
                isBuiltIn: true, sortOrder: index
            ))
        }
        try context.save()
        return builtIn.count
    }
}
