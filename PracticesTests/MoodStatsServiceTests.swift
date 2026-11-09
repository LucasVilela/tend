import XCTest
@testable import Practices

final class MoodStatsServiceTests: XCTestCase {
    private let service = MoodStatsService(calendar: TestClock.calendar)
    private let now = TestClock.now

    private func checkIn(_ day: Int, _ hour: Int, _ moods: MoodKind...) -> MoodCheckIn {
        MoodCheckIn(date: TestClock.at(day, hour), moods: moods)
    }

    /// The check-ins from the design, newest first.
    private var designCheckIns: [MoodCheckIn] {
        [
            checkIn(0, 13, .calm),
            checkIn(0, 7, .anxious, .badSleep),
            checkIn(-1, 21, .happy),
            checkIn(-2, 18, .grateful),
            checkIn(-3, 22, .anxious),
            checkIn(-5, 15, .bleh),
        ]
    }

    // MARK: Dominant mood

    func testDesignExampleIsMostlyCalmWithSomeAnxious() throws {
        // Calm 5, Anxious 4 + 1 = 5, Bad sleep 4, Happy 3, Grateful 2 → tie goes to Calm (newer).
        let result = try XCTUnwrap(service.dominant(designCheckIns.shuffled()))
        XCTAssertEqual(result.mood, .calm)
        XCTAssertEqual(result.runnerUp, .anxious)
        XCTAssertEqual(result.scores[.calm], 5)
        XCTAssertEqual(result.scores[.anxious], 5)
        XCTAssertEqual(result.scores[.badSleep], 4)
        XCTAssertNil(result.scores[.bleh], "Only the last 5 check-ins count")
    }

    func testNoCheckInsMeansNoDominantMood() {
        XCTAssertNil(service.dominant([]))
    }

    func testFewerThanFiveUseTheSameWeights() throws {
        let result = try XCTUnwrap(service.dominant([checkIn(0, 9, .sad), checkIn(-1, 9, .happy)]))
        XCTAssertEqual(result.mood, .sad)
        XCTAssertEqual(result.scores[.sad], 5)
        XCTAssertEqual(result.scores[.happy], 4)
        XCTAssertEqual(result.runnerUp, .happy)
    }

    func testRunnerUpNeedsAScoreOfThree() throws {
        let result = try XCTUnwrap(service.dominant([
            checkIn(0, 9, .calm), checkIn(-1, 9, .calm), checkIn(-2, 9, .calm), checkIn(-3, 9, .calm), checkIn(-4, 9, .sad),
        ]))
        XCTAssertEqual(result.mood, .calm)
        XCTAssertNil(result.runnerUp, "Sad scores 1")
    }

    func testTieWithinOneCheckInGoesToTheFirstPicked() throws {
        let result = try XCTUnwrap(service.dominant([checkIn(0, 9, .grateful, .happy)]))
        XCTAssertEqual(result.mood, .grateful)
        XCTAssertEqual(result.runnerUp, .happy)
    }

    // MARK: Mostly

    func testMostFrequentCountsCheckInsInThePeriod() {
        let checkIns = designCheckIns + [checkIn(-7, 9, .calm), checkIn(-8, 9, .calm), checkIn(-20, 9, .sad), checkIn(-21, 9, .sad), checkIn(-22, 9, .sad)]
        let month = TestClock.calendar.dateInterval(of: .month, for: now)!
        XCTAssertEqual(service.mostFrequent(checkIns, from: month.start, to: month.end), .calm)
    }

    func testMostFrequentTieGoesToMostRecent() {
        let month = TestClock.calendar.dateInterval(of: .month, for: now)!
        XCTAssertEqual(service.mostFrequent([checkIn(-1, 9, .sad), checkIn(0, 9, .happy)], from: month.start, to: month.end), .happy)
    }

    // MARK: Quick faces

    func testQuickFacesDefaultWithNoHistory() {
        XCTAssertEqual(service.quickFaces([], now: now), [.happy, .calm, .anxious, .bleh])
    }

    func testQuickFacesUseMostUsedInPickerOrder() {
        let checkIns = [
            checkIn(-1, 9, .sad), checkIn(-2, 9, .sad), checkIn(-3, 9, .sad),
            checkIn(-4, 9, .grateful), checkIn(-5, 9, .grateful),
            checkIn(-6, 9, .mad), checkIn(-7, 9, .stressed), checkIn(-8, 9, .lonely),
        ]
        // Sad 3, Grateful 2, then Mad (newest of the 1s), Stressed; none are defaults, so picker order.
        XCTAssertEqual(service.quickFaces(checkIns, now: now), [.grateful, .stressed, .sad, .mad])
    }

    func testQuickFacesPadWithDefaultsAndIgnoreOldCheckIns() {
        let checkIns = [checkIn(-2, 9, .sad), checkIn(-40, 9, .mad), checkIn(-41, 9, .mad)]
        XCTAssertEqual(service.quickFaces(checkIns, now: now), [.happy, .calm, .anxious, .sad])
    }

    // MARK: Pattern line

    /// The design's week: exercise on Tue, Thu, Sat, Sun; meditation every day but Tue; today partial.
    private func designStatus(_ practice: Practice, _ day: Date) -> DayStatus {
        let offset = TestClock.calendar.dateComponents([.day], from: TestClock.day(0), to: TestClock.calendar.startOfDay(for: day)).day!
        switch practice {
        case .exercise: return [-6, -4, -2, -1, -7].contains(offset) ? .done : .none
        case .meditation: return offset == 0 ? .partial : offset == -6 ? .none : .done
        case .journal: return offset == -4 ? .none : .done
        }
    }

    func testDesignPatternLine() {
        let checkIns = designCheckIns + [checkIn(-7, 19, .calm), checkIn(-8, 20, .calm)]
        let lines = service.patterns(checkIns, now: now, status: designStatus)
        XCTAssertEqual(lines.map(\.plainText), [
            "Anxious showed up twice this week, both on days you skipped exercise.",
            "Calm tends to follow your meditation days.",
        ])
        XCTAssertEqual(lines.first?.segments.first, .mood(.anxious))
    }

    func testNoPatternWhenDaysDisagree() {
        // Anxious on a day with exercise and a day without: no shared condition for exercise.
        let checkIns = [checkIn(0, 9, .anxious), checkIn(-1, 9, .anxious)]
        let lines = service.patterns(checkIns, now: now) { practice, day in
            guard practice == .exercise else { return .done }
            return TestClock.calendar.isDate(day, inSameDayAs: TestClock.day(-1)) ? .done : .none
        }
        XCTAssertTrue(lines.isEmpty)
    }

    func testNoPatternForASingleAppearance() {
        let lines = service.patterns([checkIn(0, 9, .anxious)], now: now) { _, _ in .none }
        XCTAssertTrue(lines.isEmpty)
    }

    func testOlderThanAWeekSaysLatelyAndOutsideFourteenDaysIsIgnored() {
        let checkIns = [checkIn(-9, 9, .sad), checkIn(-10, 9, .sad), checkIn(-11, 9, .sad), checkIn(-20, 9, .sad)]
        let lines = service.patterns(checkIns, now: now) { practice, _ in practice == .meditation ? .none : .done }
        XCTAssertEqual(lines.map(\.plainText), ["Sad showed up three times lately, all on days you skipped meditation."])
    }
}
