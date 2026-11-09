import SwiftData
import SwiftUI

/// Insights, pushed from Today: a month calendar with a mark per active day, and monthly totals.
struct InsightsView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \MoodLog.loggedAt, order: .reverse) private var moodLogs: [MoodLog]
    @State private var month = Calendar.practices.dateInterval(of: .month, for: .now)?.start ?? .now

    private let calendar = Calendar.practices

    var body: some View {
        DayStatsReader { stats in
            let now = Date.now
            let isCurrentMonth = calendar.isDate(month, equalTo: now, toGranularity: .month)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    PushedHeader(title: "Insights")
                        .padding(.top, 8)

                    monthHeader(isCurrentMonth: isCurrentMonth)
                        .padding(.top, 36)
                    WeekdayHeader().padding(.top, 20)
                    calendarGrid(stats: stats, now: now)
                        .padding(.top, 14)

                    VStack(spacing: 0) {
                        WaveDivider()
                        ForEach(Practice.allCases) { practice in
                            practiceRow(practice, stats: stats, now: now, isCurrentMonth: isCurrentMonth)
                                .waveBelow()
                        }
                        moodRow
                            .waveBelow()
                    }
                    .padding(.top, 28)
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Month

    private func monthHeader(isCurrentMonth: Bool) -> some View {
        HStack {
            Text(Formats.monthAndYear(month))
                .textStyle(Theme.Font.body.with(weight: 500))
                .foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            monthButton(.chevronLeft, label: "Previous month", enabled: true) { shift(-1) }
            monthButton(.chevronRight, label: "Next month", enabled: !isCurrentMonth) { shift(1) }
                .padding(.trailing, -12)
        }
    }

    private func monthButton(_ icon: Icon, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            IconView(icon: icon, size: 20, lineWidth: 1.5)
                .foregroundStyle(enabled ? Theme.textSecondary : Theme.outlineStrong)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    private func shift(_ months: Int) {
        if let next = calendar.date(byAdding: .month, value: months, to: month) {
            withAnimation(.easeInOut(duration: 0.2)) { month = next }
        }
    }

    private func calendarGrid(stats: DayStatsService, now: Date) -> some View {
        VStack(spacing: 4) {
            ForEach(Array(MonthLayout.weeks(of: month).enumerated()), id: \.offset) { _, week in
                HStack(spacing: 0) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        Group {
                            if let day { dayCell(day, stats: stats, now: now) } else { Color.clear }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                    }
                }
            }
        }
    }

    private func dayCell(_ day: Date, stats: DayStatsService, now: Date) -> some View {
        let isToday = calendar.isDate(day, inSameDayAs: now)
        let elapsed = day <= now
        let statuses = stats.statuses(on: day)
        let active = elapsed && statuses.values.contains { $0 != .none }
        return VStack(spacing: 4) {
            Text(Formats.dayNumber(day))
                .textStyle(TextStyleToken(size: 12, lineHeight: 14, weight: 400, tracking: 0))
                .foregroundStyle(isToday ? Theme.onAccent : elapsed ? Theme.textPrimary : Theme.textTertiary)
                .frame(width: 22, height: 22)
                .background { if isToday { OrganicShape.blob.fill(Theme.textPrimary) } }
            if active {
                MiniThreeCircles(statuses: statuses)
            } else {
                Color.clear.frame(width: 19, height: 16)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(dayLabel(day, statuses: statuses, active: active))
    }

    private func dayLabel(_ day: Date, statuses: [Practice: DayStatus], active: Bool) -> String {
        guard active else { return Formats.shortDay(day) }
        let parts = Practice.allCases.compactMap { p -> String? in
            switch statuses[p] ?? .none {
            case .done: "\(p.name) done"
            case .partial: "\(p.name) started"
            case .none: nil
            }
        }
        return "\(Formats.shortDay(day)): \(parts.joined(separator: ", "))"
    }

    // MARK: Rows

    private func practiceRow(_ practice: Practice, stats: DayStatsService, now: Date, isCurrentMonth: Bool) -> some View {
        let days = stats.doneDays(practice, inMonthOf: month, now: now)
        let extra: String? = switch practice {
        case .journal: isCurrentMonth ? "\(stats.streak(.journal, asOf: now))-day streak" : nil
        case .meditation, .exercise: durationLabel(stats.totalMinutes(practice, inMonthOf: month, now: now))
        }
        let detail = (["\(days.done) of \(days.of) days"] + [extra].compactMap { $0 }).joined(separator: " · ")
        let fraction = days.of == 0 ? 0 : CGFloat(days.done) / CGFloat(days.of)
        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                OrganicShape.blob.fill(practice.color).frame(width: 8, height: 8)
                Text(practice.name).textStyle(Theme.Font.body).foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 8)
                Text(detail).textStyle(Theme.Font.secondary).foregroundStyle(Theme.textSecondary)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.track)
                    Capsule().fill(practice.color).frame(width: proxy.size.width * fraction)
                }
            }
            .frame(height: 2)
        }
        .padding(.vertical, 18)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(practice.name): \(detail)")
    }

    private var moodRow: some View {
        let interval = calendar.dateInterval(of: .month, for: month)
        let inMonth = moodLogs.filter { log in interval.map { $0.contains(log.loggedAt) } ?? false }
        let mostly = interval.flatMap { MoodStatsService(calendar: calendar).mostFrequent(inMonth.map(MoodCheckIn.init), from: $0.start, to: $0.end) }
        let detail = mostly.map { "Mostly \($0.name) · \(inMonth.count) check-in\(inMonth.count == 1 ? "" : "s")" } ?? "No check-ins"
        return Button { router.todayPath.append(.mood) } label: {
            HStack(spacing: 12) {
                OrganicShape.blob.fill(mostly?.color ?? Theme.mood).frame(width: 8, height: 8)
                Text("Mood").textStyle(Theme.Font.body).foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 8)
                Text(detail).textStyle(Theme.Font.secondary).foregroundStyle(Theme.textSecondary)
                IconView(icon: .chevronRight, size: 16, lineWidth: 1.5).foregroundStyle(Theme.textTertiary)
            }
            .frame(minHeight: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mood: \(detail)")
        .accessibilityHint("Opens Mood")
        .accessibilityAddTraits(.isButton)
    }
}

/// Three small overlapping circles for one day: journal and meditation on top, exercise below.
/// Done = tinted fill with an outline, started = outline, nothing = faint outline.
struct MiniThreeCircles: View {
    let statuses: [Practice: DayStatus]

    private static let offsets: [Practice: CGPoint] = [
        .journal: CGPoint(x: 0, y: 0), .meditation: CGPoint(x: 8, y: 0), .exercise: CGPoint(x: 4, y: 6),
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Practice.allCases) { practice in
                let status = statuses[practice] ?? .none
                let offset = Self.offsets[practice]!
                ZStack {
                    if status == .done { OrganicShape.blob.fill(practice.color.opacity(0.35)) }
                    OrganicShape.blob.strokeBorder(status == .none ? Theme.outline : practice.color, lineWidth: 1)
                }
                .frame(width: 11, height: 11)
                .offset(x: offset.x, y: offset.y)
            }
        }
        .frame(width: 19, height: 17, alignment: .topLeading)
        .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack { InsightsView() }
        .environment(AppRouter())
        .modelContainer(SampleData.previewContainer)
        .preferredColorScheme(.dark)
}
