import XCTest
@testable import Practices

final class WorkoutTitleTests: XCTestCase {
    func testTitlesReadNaturally() {
        let cal = TestClock.calendar
        XCTAssertEqual(WorkoutTitle.make(type: .run, intensity: .easy, at: TestClock.at(0, 7), calendar: cal), "Easy morning run")
        XCTAssertEqual(WorkoutTitle.make(type: .cycle, intensity: .hard, at: TestClock.at(0, 19), calendar: cal), "Hard evening ride")
        XCTAssertEqual(WorkoutTitle.make(type: .strength, intensity: .moderate, at: TestClock.at(0, 13), calendar: cal), "Moderate afternoon strength session")
        XCTAssertEqual(WorkoutTitle.make(type: .other, intensity: .easy, at: TestClock.at(0, 23), calendar: cal), "Easy late workout")
    }
}
