import SwiftUI

/// The rolling last 7 days: weekday initial, date and a dot per practice. The shown day sits in a
/// filled blob (today unless a past day was tapped); today keeps a faint outline when another day is shown.
struct WeekStrip: View {
    struct Day: Identifiable {
        let date: Date
        let statuses: [Practice: DayStatus]
        let isToday: Bool
        var isSelected: Bool
        var id: Date { date }
    }

    let days: [Day]
    var onSelect: (Date) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days) { day in
                Button { onSelect(day.date) } label: { dayView(day) }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(label(for: day))
                    .accessibilityHint(day.isSelected ? "" : "Shows this day")
                    .accessibilityAddTraits(day.isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Last 7 days")
    }

    private func dayView(_ day: Day) -> some View {
        VStack(spacing: 8) {
            Text(Formats.weekdayInitial(day.date))
                .textStyle(Theme.Font.micro)
                .foregroundStyle(Theme.textTertiary)
            Text(Formats.dayNumber(day.date))
                .textStyle(Theme.Font.bodyLong.with(size: 15, lineHeight: 20))
                .foregroundStyle(day.isSelected ? Theme.onAccent : day.isToday ? Theme.textPrimary : Theme.textSecondary)
                .frame(width: 34, height: 34)
                .background {
                    if day.isSelected {
                        OrganicShape.blob.fill(Theme.textPrimary)
                    } else if day.isToday {
                        OrganicShape.blob.strokeBorder(Theme.outlineStrong, lineWidth: 1)
                    }
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
        .contentShape(Rectangle())
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
