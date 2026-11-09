import Foundation
@testable import Practices

/// A fixed calendar and clock: Monday 9 November 2026, 8:40 pm UTC, weeks starting Monday.
enum TestClock {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.locale = Locale(identifier: "en_GB")
        return cal
    }()

    static let now = at(0, 20, 40)

    /// A time `dayOffset` days from 9 Nov 2026.
    static func at(_ dayOffset: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        let base = calendar.date(from: DateComponents(year: 2026, month: 11, day: 9))!
        let day = calendar.date(byAdding: .day, value: dayOffset, to: base)!
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    static func day(_ offset: Int) -> Date { at(offset, 0) }
}
