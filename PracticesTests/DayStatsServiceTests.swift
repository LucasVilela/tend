import XCTest
@testable import Practices

final class DayStatsServiceTests: XCTestCase {
    private let cal = TestClock.calendar
    private let now = TestClock.now
    private typealias S = ActivitySnapshot

    private func service(_ snapshot: ActivitySnapshot, goals: Goals = Goals()) -> DayStatsService {
        DayStatsService(snapshot: snapshot, goals: goals, calendar: cal)
    }

    // MARK: Day status

    func testJournalDoneWithLogOrGuidedEntry() {
        let s = service(S(journalLogs: [.init(date: TestClock.at(0, 7, 12))], guidedEntries: [TestClock.at(-1, 21, 40)]))
        XCTAssertEqual(s.status(.journal, on: now), .done)
        XCTAssertEqual(s.status(.journal, on: TestClock.day(-1)), .done)
        XCTAssertEqual(s.status(.journal, on: TestClock.day(-2)), .none)
    }

    func testMeditationPartialThenDoneAtGoal() {
        var snap = S(meditations: [.init(date: TestClock.at(0, 6, 40), minutes: 10)])
        XCTAssertEqual(service(snap).status(.meditation, on: now), .partial)
        snap.meditations.append(.init(date: TestClock.at(0, 18), minutes: 5))
        XCTAssertEqual(service(snap).status(.meditation, on: now), .done)
    }

    func testCheckMarksDoneWithoutMinutes() {
        let s = service(S(checks: [.init(day: TestClock.day(0), practice: .exercise, checkedAt: now)]))
        XCTAssertEqual(s.status(.exercise, on: now), .done)
        XCTAssertEqual(s.status(.meditation, on: now), .none)
    }

    func testExerciseUsesExerciseGoal() {
        let snap = S(workouts: [.init(date: TestClock.at(0, 7), minutes: 20)])
        XCTAssertEqual(service(snap).status(.exercise, on: now), .partial)
        XCTAssertEqual(service(snap, goals: Goals(meditationMinutes: 15, exerciseMinutes: 20)).status(.exercise, on: now), .done)
    }

    func testMinutesSumAcrossLogsOnTheSameDayOnly() {
        let snap = S(meditations: [
            .init(date: TestClock.at(0, 6), minutes: 5),
            .init(date: TestClock.at(0, 22), minutes: 5),
            .init(date: TestClock.at(-1, 23, 59), minutes: 30),
        ])
        XCTAssertEqual(service(snap).minutes(.meditation, on: now), 10)
    }

    func testDoneCountIgnoresPartial() {
        let snap = S(
            journalLogs: [.init(date: TestClock.at(0, 7))],
            meditations: [.init(date: TestClock.at(0, 7), minutes: 10)],
            checks: [.init(day: TestClock.day(0), practice: .exercise, checkedAt: now)]
        )
        XCTAssertEqual(service(snap).doneCount(on: now), 2)
    }

    // MARK: Check-off

    func testCheckOffActions() {
        let s = service(S(
            journalLogs: [.init(date: TestClock.at(0, 7), isQuickCheck: true)],
            workouts: [.init(date: TestClock.at(0, 7), minutes: 45)]
        ))
        XCTAssertEqual(s.checkOffAction(.journal, on: now), .undo)
        XCTAssertEqual(s.checkOffAction(.meditation, on: now), .check)
        XCTAssertEqual(s.checkOffAction(.exercise, on: now), .none, "Done through a detailed log: nothing to undo")
    }

    func testPartialPracticeCanBeCheckedOff() {
        let s = service(S(meditations: [.init(date: TestClock.at(0, 7), minutes: 10)]))
        XCTAssertEqual(s.checkOffAction(.meditation, on: now), .check)
    }

    func testUndoAvailableEvenWhenDetailedLogAlsoExists() {
        let s = service(S(
            journalLogs: [.init(date: TestClock.at(0, 7), isQuickCheck: true), .init(date: TestClock.at(0, 9))]
        ))
        XCTAssertEqual(s.checkOffAction(.journal, on: now), .undo)
    }

    // MARK: Streaks

    func testStreakEndsTodayWhenTodayIsDone() {
        let logs = [0, -1, -2, -3, -5].map { ActivitySnapshot.Journal(date: TestClock.at($0, 8)) }
        XCTAssertEqual(service(S(journalLogs: logs)).streak(.journal, asOf: now), 4)
    }

    func testStreakEndsYesterdayWhenTodayIsNotDone() {
        let meditations = [-1, -2, -3, -4, -5].map { ActivitySnapshot.Minutes(date: TestClock.at($0, 7), minutes: 15) }
            + [.init(date: TestClock.at(0, 6), minutes: 10)]
        XCTAssertEqual(service(S(meditations: meditations)).streak(.meditation, asOf: now), 5)
    }

    func testStreakIsZeroAfterAMissedYesterday() {
        let s = service(S(journalLogs: [.init(date: TestClock.at(-2, 8))]))
        XCTAssertEqual(s.streak(.journal, asOf: now), 0)
    }

    // MARK: Month

    func testMonthCountsUpToToday() {
        let logs = [0, -1, -2, -3, -5, -6, -7, -8].map { ActivitySnapshot.Journal(date: TestClock.at($0, 8)) }
            + [.init(date: TestClock.at(-9, 8))] // 31 October, outside the month
        let s = service(S(journalLogs: logs))
        let result = s.doneDays(.journal, inMonthOf: now, now: now)
        XCTAssertEqual(result.done, 8)
        XCTAssertEqual(result.of, 9)
    }

    func testMonthMinutes() {
        let s = service(S(workouts: [
            .init(date: TestClock.at(-1, 7), minutes: 32), .init(date: TestClock.at(-9, 7), minutes: 60),
        ]))
        XCTAssertEqual(s.totalMinutes(.exercise, inMonthOf: now, now: now), 32)
    }

    // MARK: Fill and copy

    func testFill() {
        let s = service(S(meditations: [.init(date: TestClock.at(0, 7), minutes: 10)]))
        XCTAssertEqual(s.fill(.meditation, on: now), 10.0 / 15.0, accuracy: 0.001)
        XCTAssertEqual(s.fill(.exercise, on: now), 0)
        XCTAssertEqual(s.fill(.journal, on: now), 0)
    }

    func testStatusLines() {
        let s = service(S(
            journalLogs: [.init(date: TestClock.at(0, 9, 30))],
            guidedEntries: [TestClock.at(0, 7, 12)],
            meditations: [.init(date: TestClock.at(0, 6, 40), minutes: 10)]
        ))
        XCTAssertEqual(s.statusLine(.journal, now: now), "Done · 7:12 am")
        XCTAssertEqual(s.statusLine(.meditation, now: now), "10 of 15 min")
        XCTAssertEqual(s.statusLine(.exercise, now: now), "0 of 30 min")
        XCTAssertEqual(service(S()).statusLine(.journal, now: now), "Not yet")
    }

    func testStatusLinesForAPastDay() {
        let s = service(S(
            journalLogs: [.init(date: TestClock.at(-1, 21, 40))],
            meditations: [.init(date: TestClock.at(-2, 7), minutes: 5)]
        ))
        XCTAssertEqual(s.statusLine(.journal, on: TestClock.day(-1), now: now), "Done · 9:40 pm")
        XCTAssertEqual(s.statusLine(.journal, on: TestClock.day(-2), now: now), "Not logged")
        XCTAssertEqual(s.statusLine(.meditation, on: TestClock.day(-2), now: now), "5 of 15 min")
    }
}
