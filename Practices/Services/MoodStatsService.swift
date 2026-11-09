import Foundation

/// A mood check-in as plain values.
struct MoodCheckIn: Hashable, Sendable {
    var date: Date
    var moods: [MoodKind]
    var note: String? = nil
}

extension MoodCheckIn {
    init(_ log: MoodLog) { self.init(date: log.loggedAt, moods: log.moods, note: log.note) }
}

/// The face on the Mood screen: the dominant recent mood and, if strong enough, a runner-up.
struct DominantMood: Equatable, Sendable {
    var mood: MoodKind
    var runnerUp: MoodKind?
    var scores: [MoodKind: Int]
}

/// One observation linking moods to practices, split so mood names can be coloured.
struct PatternLine: Equatable, Sendable {
    enum Segment: Equatable, Sendable {
        case text(String)
        case mood(MoodKind)
    }

    var segments: [Segment]

    var plainText: String {
        segments.map {
            switch $0 {
            case .text(let s): s
            case .mood(let m): m.name
            }
        }.joined()
    }
}

/// Mood rules (SPEC §7): dominant mood, "mostly" mood, quick faces and the pattern line.
struct MoodStatsService {
    var calendar: Calendar = .practices

    static let dominantWindow = 5
    static let runnerUpMinimum = 3
    static let quickFaceDefaults: [MoodKind] = [.happy, .calm, .anxious, .bleh]
    static let quickFaceDays = 30
    static let patternDays = 14

    // MARK: Ranking

    private struct Rank {
        var score = 0
        /// Index of the newest check-in it appears in (0 = newest), then its position in that check-in.
        var newest = (checkIn: Int.max, position: Int.max)
    }

    /// Ranks moods by score, ties going to the one that appears most recently.
    private func ranked(_ newestFirst: [MoodCheckIn], weight: (Int) -> Int) -> [(MoodKind, Rank)] {
        var ranks: [MoodKind: Rank] = [:]
        for (index, checkIn) in newestFirst.enumerated() {
            for (position, mood) in checkIn.moods.enumerated() {
                var rank = ranks[mood, default: Rank()]
                rank.score += weight(index)
                if (index, position) < rank.newest { rank.newest = (index, position) }
                ranks[mood] = rank
            }
        }
        return ranks.sorted { a, b in
            if a.value.score != b.value.score { return a.value.score > b.value.score }
            return a.value.newest < b.value.newest
        }
    }

    private func newestFirst(_ checkIns: [MoodCheckIn]) -> [MoodCheckIn] {
        checkIns.sorted { $0.date > $1.date }
    }

    // MARK: Dominant mood

    /// Weighted count over the 5 most recent check-ins (weights 5, 4, 3, 2, 1, newest heaviest).
    /// Every mood in a check-in gets that check-in's weight. Nil when there are no check-ins.
    func dominant(_ checkIns: [MoodCheckIn]) -> DominantMood? {
        let recent = Array(newestFirst(checkIns).prefix(Self.dominantWindow))
        let ranking = ranked(recent) { Self.dominantWindow - $0 }
        guard let first = ranking.first else { return nil }
        let second = ranking.dropFirst().first
        let runnerUp = second.flatMap { $0.1.score >= Self.runnerUpMinimum ? $0.0 : nil }
        return DominantMood(
            mood: first.0,
            runnerUp: runnerUp,
            scores: Dictionary(uniqueKeysWithValues: ranking.map { ($0.0, $0.1.score) })
        )
    }

    /// The mood in the most check-ins between `start` (inclusive) and `end` (exclusive); ties go to the most recent.
    func mostFrequent(_ checkIns: [MoodCheckIn], from start: Date, to end: Date) -> MoodKind? {
        let inRange = newestFirst(checkIns).filter { $0.date >= start && $0.date < end }
        return ranked(inRange) { _ in 1 }.first?.0
    }

    // MARK: Quick faces

    /// The 4 most-used moods over the last 30 days, padded with Happy, Calm, Anxious, Bleh.
    /// Returned in a stable order (the defaults in the design's order, then picker order) so the row
    /// doesn't reshuffle after every check-in.
    func quickFaces(_ checkIns: [MoodCheckIn], now: Date) -> [MoodKind] {
        let start = calendar.date(byAdding: .day, value: -Self.quickFaceDays, to: now) ?? now
        let recent = newestFirst(checkIns).filter { $0.date > start && $0.date <= now }
        var picks = ranked(recent) { _ in 1 }.prefix(4).map(\.0)
        for mood in Self.quickFaceDefaults where picks.count < 4 && !picks.contains(mood) {
            picks.append(mood)
        }
        func position(_ mood: MoodKind) -> Int {
            Self.quickFaceDefaults.firstIndex(of: mood) ?? (Self.quickFaceDefaults.count + MoodKind.allCases.firstIndex(of: mood)!)
        }
        return picks.sorted { position($0) < position($1) }
    }

    // MARK: Pattern line

    private enum Condition {
        case skipped(Practice)
        case practiced(Practice)
    }

    private struct Observation {
        var mood: MoodKind
        var count: Int
        var newest: Date
        var thisWeek: Bool
        var condition: Condition
    }

    /// Up to two gentle observations from the last 14 days. A mood qualifies when it appears in at
    /// least 2 check-ins and every one of those days shares the same practice condition: the practice
    /// was skipped (nothing logged) or practised (anything logged). Unpleasant moods are linked to
    /// skipped practices, pleasant moods to practised ones. Empty when nothing qualifies.
    func patterns(_ checkIns: [MoodCheckIn], now: Date, status: (Practice, Date) -> DayStatus) -> [PatternLine] {
        let today = calendar.startOfDay(for: now)
        guard let windowStart = calendar.date(byAdding: .day, value: -(Self.patternDays - 1), to: today),
              let weekStart = calendar.date(byAdding: .day, value: -6, to: today) else { return [] }
        let recent = checkIns.filter { $0.date >= windowStart && $0.date <= now }

        var byMood: [MoodKind: [Date]] = [:]
        for checkIn in recent {
            for mood in Set(checkIn.moods) { byMood[mood, default: []].append(checkIn.date) }
        }

        var unpleasant: [Observation] = []
        var pleasant: [Observation] = []
        for (mood, dates) in byMood where dates.count >= 2 {
            let days = Set(dates.map { calendar.startOfDay(for: $0) })
            let newest = dates.max() ?? now
            let thisWeek = dates.allSatisfy { $0 >= weekStart }
            if mood.isPleasant {
                if let p = [Practice.meditation, .exercise, .journal].first(where: { p in days.allSatisfy { status(p, $0) != .none } }) {
                    pleasant.append(Observation(mood: mood, count: dates.count, newest: newest, thisWeek: thisWeek, condition: .practiced(p)))
                }
            } else {
                if let p = [Practice.exercise, .meditation, .journal].first(where: { p in days.allSatisfy { status(p, $0) == .none } }) {
                    unpleasant.append(Observation(mood: mood, count: dates.count, newest: newest, thisWeek: thisWeek, condition: .skipped(p)))
                }
            }
        }

        let order: (Observation, Observation) -> Bool = {
            $0.count != $1.count ? $0.count > $1.count : $0.newest > $1.newest
        }
        unpleasant.sort(by: order)
        pleasant.sort(by: order)

        var chosen: [Observation] = []
        if let first = unpleasant.first { chosen.append(first) }
        if let first = pleasant.first { chosen.append(first) }
        if chosen.count < 2 {
            chosen += (unpleasant.dropFirst() + pleasant.dropFirst()).sorted(by: order).prefix(2 - chosen.count)
        }
        return chosen.map(sentence)
    }

    private func sentence(_ o: Observation) -> PatternLine {
        switch o.condition {
        case .skipped(let practice):
            let times = o.count == 2 ? "twice" : o.count == 3 ? "three times" : "\(o.count) times"
            let when = o.thisWeek ? "this week" : "lately"
            let quantifier = o.count == 2 ? "both" : "all"
            return PatternLine(segments: [
                .mood(o.mood),
                .text(" showed up \(times) \(when), \(quantifier) on days you skipped \(practice.activityNoun)."),
            ])
        case .practiced(let practice):
            return PatternLine(segments: [
                .mood(o.mood),
                .text(" tends to follow your \(practice.activityNoun) days."),
            ])
        }
    }
}
