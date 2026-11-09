import Foundation
import SwiftData

/// Writes for the one-tap actions on Today. Decisions come from the stats services; this applies them.
@MainActor
struct PracticeActions {
    let context: ModelContext
    var calendar: Calendar = .practices

    /// Toggles today's check-off for a practice (SPEC §7, fast check-off) and returns what happened.
    @discardableResult
    func toggleCheckOff(_ practice: Practice, stats: DayStatsService, now: Date = .now) -> CheckOffAction {
        let action = stats.checkOffAction(practice, on: now)
        let day = calendar.startOfDay(for: now)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? now
        switch action {
        case .check:
            if practice == .journal {
                context.insert(JournalLog(loggedAt: now, isQuickCheck: true))
            } else {
                context.insert(DailyCheck(day: day, practice: practice, checkedAt: now))
            }
        case .undo:
            if practice == .journal {
                let quick = FetchDescriptor<JournalLog>(predicate: #Predicate {
                    $0.isQuickCheck && $0.loggedAt >= day && $0.loggedAt < nextDay
                })
                for log in (try? context.fetch(quick)) ?? [] { context.delete(log) }
            } else {
                let raw = practice.rawValue
                let checks = FetchDescriptor<DailyCheck>(predicate: #Predicate {
                    $0.practiceRaw == raw && $0.day >= day && $0.day < nextDay
                })
                for check in (try? context.fetch(checks)) ?? [] { context.delete(check) }
            }
        case .none:
            break
        }
        try? context.save()
        return action
    }

    /// One-tap mood from Today's quick faces.
    /// - Tapping the selected face removes that check-in.
    /// - Tapping another face right after a quick tap (within 2 minutes) changes that check-in.
    /// - Otherwise it logs a new single-mood check-in now.
    func quickMood(_ mood: MoodKind, selected: MoodLog?, now: Date = .now) {
        if let selected, selected.moods == [mood] {
            context.delete(selected)
        } else if let selected, selected.moods.count == 1, now.timeIntervalSince(selected.loggedAt) < 120 {
            selected.moods = [mood]
            selected.loggedAt = now
        } else {
            context.insert(MoodLog(loggedAt: now, moods: [mood]))
        }
        try? context.save()
    }
}
