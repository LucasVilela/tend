import Foundation

/// How far a practice got on one day.
enum DayStatus: Int, Comparable, Sendable {
    case none, partial, done
    static func < (lhs: DayStatus, rhs: DayStatus) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// What a one-tap check-off should do right now.
enum CheckOffAction: Equatable, Sendable {
    /// Mark the practice done (a quick `JournalLog` or a `DailyCheck`).
    case check
    /// Remove today's quick check-off. Detailed logs are never removed.
    case undo
    /// Already done through detailed logs; there's no check-off to toggle.
    case none
}

struct Goals: Equatable, Sendable {
    var meditationMinutes = Tokens.Defaults.meditationMinutesPerDay
    var exerciseMinutes = Tokens.Defaults.exerciseMinutesPerDay

    func minutes(for practice: Practice) -> Int? {
        switch practice {
        case .journal: nil
        case .meditation: meditationMinutes
        case .exercise: exerciseMinutes
        }
    }
}

/// Plain values copied out of SwiftData, so the rules can be tested without a store.
struct ActivitySnapshot: Sendable {
    struct Journal: Sendable { var date: Date; var isQuickCheck = false }
    struct Minutes: Sendable { var date: Date; var minutes: Int }
    struct Check: Sendable { var day: Date; var practice: Practice; var checkedAt: Date }

    var journalLogs: [Journal] = []
    var guidedEntries: [Date] = []
    var meditations: [Minutes] = []
    var workouts: [Minutes] = []
    var checks: [Check] = []
}

extension ActivitySnapshot {
    init(journalLogs: [JournalLog], guidedEntries: [GuidedEntry], meditations: [MeditationLog],
         workouts: [Workout], checks: [DailyCheck]) {
        self.init(
            journalLogs: journalLogs.map { Journal(date: $0.loggedAt, isQuickCheck: $0.isQuickCheck) },
            guidedEntries: guidedEntries.map(\.createdAt),
            meditations: meditations.map { Minutes(date: $0.loggedAt, minutes: $0.minutes) },
            workouts: workouts.map { Minutes(date: $0.startedAt, minutes: $0.durationMinutes) },
            checks: checks.map { Check(day: $0.day, practice: $0.practice, checkedAt: $0.checkedAt) }
        )
    }
}

/// Day status, check-offs and streaks for the three practices (SPEC §7).
struct DayStatsService {
    let calendar: Calendar
    let goals: Goals

    private var journalTimes: [Date: [Date]] = [:]
    private var quickJournalDays: Set<Date> = []
    private var minutesByDay: [Practice: [Date: Int]] = [:]
    private var checkDays: [Practice: Set<Date>] = [:]

    init(snapshot: ActivitySnapshot, goals: Goals = Goals(), calendar: Calendar = .practices) {
        self.calendar = calendar
        self.goals = goals
        for log in snapshot.journalLogs {
            let day = calendar.startOfDay(for: log.date)
            journalTimes[day, default: []].append(log.date)
            if log.isQuickCheck { quickJournalDays.insert(day) }
        }
        for date in snapshot.guidedEntries {
            journalTimes[calendar.startOfDay(for: date), default: []].append(date)
        }
        for m in snapshot.meditations {
            minutesByDay[.meditation, default: [:]][calendar.startOfDay(for: m.date), default: 0] += m.minutes
        }
        for w in snapshot.workouts {
            minutesByDay[.exercise, default: [:]][calendar.startOfDay(for: w.date), default: 0] += w.minutes
        }
        for c in snapshot.checks {
            checkDays[c.practice, default: []].insert(calendar.startOfDay(for: c.day))
        }
    }

    // MARK: Day status

    func minutes(_ practice: Practice, on day: Date) -> Int {
        minutesByDay[practice]?[calendar.startOfDay(for: day)] ?? 0
    }

    /// A one-tap check-off exists for this day (a quick journal log or a `DailyCheck`).
    func hasQuickCheck(_ practice: Practice, on day: Date) -> Bool {
        let key = calendar.startOfDay(for: day)
        return practice == .journal ? quickJournalDays.contains(key) : checkDays[practice]?.contains(key) == true
    }

    func status(_ practice: Practice, on day: Date) -> DayStatus {
        let key = calendar.startOfDay(for: day)
        switch practice {
        case .journal:
            return journalTimes[key]?.isEmpty == false ? .done : .none
        case .meditation, .exercise:
            let goal = goals.minutes(for: practice) ?? 0
            let total = minutes(practice, on: key)
            if total >= goal || checkDays[practice]?.contains(key) == true { return .done }
            return total > 0 ? .partial : .none
        }
    }

    func statuses(on day: Date) -> [Practice: DayStatus] {
        Dictionary(uniqueKeysWithValues: Practice.allCases.map { ($0, status($0, on: day)) })
    }

    /// "x of 3": practices done on the day. Mood doesn't count.
    func doneCount(on day: Date) -> Int {
        Practice.allCases.filter { status($0, on: day) == .done }.count
    }

    /// How full the buddy is: 1 when done, otherwise logged minutes against the goal.
    func fill(_ practice: Practice, on day: Date) -> Double {
        switch status(practice, on: day) {
        case .done: return 1
        case .none: return 0
        case .partial:
            let goal = Double(max(1, goals.minutes(for: practice) ?? 1))
            return min(0.95, max(0.08, Double(minutes(practice, on: day)) / goal))
        }
    }

    /// Earliest journaling (log or guided entry) on the day.
    func firstJournalTime(on day: Date) -> Date? {
        journalTimes[calendar.startOfDay(for: day)]?.min()
    }

    // MARK: Check-off

    func checkOffAction(_ practice: Practice, on day: Date) -> CheckOffAction {
        if hasQuickCheck(practice, on: day) { return .undo }
        return status(practice, on: day) == .done ? .none : .check
    }

    // MARK: Streaks

    /// Consecutive done days ending today if today is done, otherwise ending yesterday.
    func streak(_ practice: Practice, asOf now: Date) -> Int {
        var day = calendar.startOfDay(for: now)
        if status(practice, on: day) != .done {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var count = 0
        while status(practice, on: day) == .done {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    // MARK: Month

    /// Days in the month of `date` up to and including `now` (all of it for past months).
    func elapsedDays(inMonthOf date: Date, now: Date) -> [Date] {
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return [] }
        let today = calendar.startOfDay(for: now)
        var days: [Date] = []
        var day = interval.start
        while day < interval.end && day <= today {
            days.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return days
    }

    func doneDays(_ practice: Practice, inMonthOf date: Date, now: Date) -> (done: Int, of: Int) {
        let days = elapsedDays(inMonthOf: date, now: now)
        return (days.filter { status(practice, on: $0) == .done }.count, days.count)
    }

    func totalMinutes(_ practice: Practice, inMonthOf date: Date, now: Date) -> Int {
        elapsedDays(inMonthOf: date, now: now).reduce(0) { $0 + minutes(practice, on: $1) }
    }

    // MARK: Copy

    /// The status line under each practice on Today: "Done · 7:12 am", "10 of 15 min", "0 of 30 min".
    func statusLine(_ practice: Practice, now: Date) -> String {
        let state = status(practice, on: now)
        switch practice {
        case .journal:
            guard state == .done else { return "Not yet" }
            return firstJournalTime(on: now).map { "Done · \(Formats.time($0, calendar: calendar))" } ?? "Done"
        case .meditation, .exercise:
            if state == .done { return "Done" }
            return "\(minutes(practice, on: now)) of \(goals.minutes(for: practice) ?? 0) min"
        }
    }
}
