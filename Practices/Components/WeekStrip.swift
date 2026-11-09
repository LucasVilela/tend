import SwiftUI

/// The rolling last 7 days: weekday initial, date (today in a filled blob) and a dot per practice.
struct WeekStrip: View {
    struct Day: Identifiable {
        let date: Date
        let statuses: [Practice: DayStatus]
        let isToday: Bool
        var id: Date { date }
    }

    let days: [Day]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days) { day in
                VStack(spacing: 8) {
                    Text(Formats.weekdayInitial(day.date))
                        .textStyle(Theme.Font.micro)
                        .foregroundStyle(Theme.textTertiary)
                    Text(Formats.dayNumber(day.date))
                        .textStyle(Theme.Font.bodyLong.with(size: 15, lineHeight: 20))
                        .foregroundStyle(day.isToday ? Theme.onAccent : Theme.textSecondary)
                        .frame(width: 34, height: 34)
                        .background {
                            if day.isToday { OrganicShape.blob.fill(Theme.textPrimary) }
                        }
                    HStack(spacing: 4) {
                        ForEach(Practice.allCases) { practice in
                            OrganicShape.blob
                                .fill(dotColor(practice, day.statuses[practice] ?? .none))
                                .frame(width: 4, height: 4)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label(for: day))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Last 7 days")
    }

    private func dotColor(_ practice: Practice, _ status: DayStatus) -> Color {
        switch status {
        case .done: practice.color
        case .partial: practice.color.opacity(Theme.partialOpacity)
        case .none: Theme.track
        }
    }

    private func label(for day: Day) -> String {
        let done = Practice.allCases.compactMap { p -> String? in
            switch day.statuses[p] ?? .none {
            case .done: p.name.lowercased()
            case .partial: "\(p.name.lowercased()) in progress"
            case .none: nil
            }
        }
        let date = Formats.longDay(day.date)
        return (day.isToday ? "Today, " : "") + date + ": " + (done.isEmpty ? "nothing logged" : done.joined(separator: ", "))
    }
}
