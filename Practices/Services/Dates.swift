import Foundation

extension Calendar {
    /// Gregorian, weeks start on Monday, in the device time zone.
    static var practices: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = Tokens.Defaults.weekStartsOnMonday ? 2 : 1
        cal.locale = Locale(identifier: "en_GB")
        cal.timeZone = .current
        return cal
    }

    /// The `count` local days ending with (and including) the day of `date`, oldest first.
    func days(endingAt date: Date, count: Int) -> [Date] {
        let end = startOfDay(for: date)
        return (0..<count).reversed().compactMap { self.date(byAdding: .day, value: -$0, to: end) }
    }
}

/// App-wide text formats ("7:12 am", "Monday, 9 November", "Sun 8 Nov").
enum Formats {
    private static func formatter(_ format: String, calendar: Calendar) -> DateFormatter {
        let f = DateFormatter()
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = format
        f.amSymbol = "am"
        f.pmSymbol = "pm"
        return f
    }

    static func time(_ date: Date, calendar: Calendar = .practices) -> String {
        formatter("h:mm a", calendar: calendar).string(from: date)
    }

    static func longDay(_ date: Date, calendar: Calendar = .practices) -> String {
        formatter("EEEE, d MMMM", calendar: calendar).string(from: date)
    }

    static func shortDay(_ date: Date, calendar: Calendar = .practices) -> String {
        formatter("EEE d MMM", calendar: calendar).string(from: date)
    }

    static func weekdayInitial(_ date: Date, calendar: Calendar = .practices) -> String {
        String(formatter("EEEEE", calendar: calendar).string(from: date).prefix(1))
    }

    static func dayNumber(_ date: Date, calendar: Calendar = .practices) -> String {
        String(calendar.component(.day, from: date))
    }

    /// "Today", "Yesterday" is not used in the design; it shows "Sun 8 Nov" for other days.
    static func relativeDay(_ date: Date, now: Date, calendar: Calendar = .practices) -> String {
        calendar.isDate(date, inSameDayAs: now) ? "Today" : shortDay(date, calendar: calendar)
    }

    /// Greeting by time of day: morning before 12:00, afternoon before 18:00, evening after.
    static func greeting(at date: Date, name: String, calendar: Calendar = .practices) -> String {
        let hour = calendar.component(.hour, from: date)
        let part = hour < 12 ? "morning" : hour < 18 ? "afternoon" : "evening"
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Good \(part)" : "Good \(part), \(trimmed)"
    }
}
