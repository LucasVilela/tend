import SwiftUI

/// Weeks of a month, Monday first, with `nil` for the blanks before the 1st and after the last day.
enum MonthLayout {
    static func weeks(of month: Date, calendar: Calendar = .practices) -> [[Date?]] {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }
        var days: [Date?] = []
        let weekday = calendar.component(.weekday, from: interval.start)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        days += Array(repeating: nil, count: leading)
        var day = interval.start
        while day < interval.end {
            days.append(day)
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? interval.end
        }
        while days.count % 7 != 0 { days.append(nil) }
        return stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<$0 + 7]) }
    }

    /// "M T W T F S S" in the calendar's week order.
    static func weekdayInitials(calendar: Calendar = .practices) -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        return (0..<7).map { symbols[(calendar.firstWeekday - 1 + $0) % 7] }
    }
}

/// The row of weekday initials over a month grid.
struct WeekdayHeader: View {
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(MonthLayout.weekdayInitials().enumerated()), id: \.offset) { _, initial in
                Text(initial)
                    .textStyle(Theme.Font.micro)
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Journal's month of dots: filled sand = journaled, outline = missed, faint outline = still to come.
struct MonthDots: View {
    let month: Date
    let now: Date
    let isDone: (Date) -> Bool
    var color: Color = Practice.journal.color
    private let calendar = Calendar.practices

    var body: some View {
        VStack(spacing: 8) {
            WeekdayHeader()
            ForEach(Array(MonthLayout.weeks(of: month).enumerated()), id: \.offset) { _, week in
                HStack(spacing: 0) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        Group {
                            if let day { dot(day) } else { Color.clear }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                    }
                }
            }
        }
    }

    private func dot(_ day: Date) -> some View {
        let done = isDone(day)
        let past = day < calendar.startOfDay(for: now)
        return Text(Formats.dayNumber(day))
            .textStyle(TextStyleToken(size: 11, lineHeight: 14, weight: 400, tracking: 0))
            .foregroundStyle(done ? Theme.onAccent : past ? Theme.textSecondary : Theme.textTertiary)
            .frame(width: 30, height: 30)
            .background {
                if done {
                    OrganicShape.blob.fill(color)
                } else {
                    OrganicShape.blob.strokeBorder(past ? Theme.outlineStrong : Theme.hairline, lineWidth: 1)
                }
            }
            .accessibilityLabel("\(Formats.shortDay(day)): \(done ? "journaled" : past ? "missed" : "not yet")")
    }
}
