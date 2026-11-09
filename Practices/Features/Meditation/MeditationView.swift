import SwiftData
import SwiftUI

/// Meditation tracker: minutes this week against a daily goal and recent sessions. No timer.
struct MeditationView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var context
    @Query(sort: \MeditationLog.loggedAt, order: .reverse) private var sessions: [MeditationLog]
    @AppStorage("meditationGoalMinutes") private var goal = Tokens.Defaults.meditationMinutesPerDay
    @State private var showingLog = false
    @State private var loggerDate: Date?

    var body: some View {
        DayStatsReader { stats in
            let now = Date.now
            let days = Calendar.practices.days(endingAt: now, count: 7)
            let bars = days.map { MiniBarChart.Bar(day: $0, minutes: stats.minutes(.meditation, on: $0), isToday: Calendar.practices.isDate($0, inSameDayAs: now)) }
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ScreenTitle(title: "Meditation")
                    Text("\(goal) minutes a day · \(stats.streak(.meditation, asOf: now))-day streak")
                        .textStyle(Theme.Font.secondary)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(bars.map(\.minutes).reduce(0, +))")
                            .textStyle(Theme.Font.displayXL)
                            .foregroundStyle(Theme.textPrimary)
                        Text("minutes in the last 7 days")
                            .textStyle(Theme.Font.secondary)
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .accessibilityElement(children: .combine)
                    .padding(.top, 36)

                    MiniBarChart(bars: bars, goal: goal, color: Practice.meditation.color, muted: Practice.meditation.mutedColor, height: 80)
                        .padding(.top, 28)

                    if !sessions.isEmpty {
                        SectionLabel(title: "Recent sessions").padding(.top, 36).padding(.bottom, 8)
                        ForEach(sessions.prefix(30)) { session in
                            DetailRow(title: session.kind?.listLabel ?? "Meditation",
                                      detail: Formats.dayAndTime(session.loggedAt)) {
                                Text(session.minutes >= 30 ? "30+ min" : "\(session.minutes) min")
                                    .textStyle(Theme.Font.bodyLong.with(size: 15, lineHeight: 20))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .waveBelow()
                            .contextMenu {
                                Button("Delete", role: .destructive) {
                                    withAnimation { context.delete(session); try? context.save() }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
        }
        .background(Theme.background.ignoresSafeArea())
        .floatingAction(color: Practice.meditation.color, label: "Log meditation") { loggerDate = nil; showingLog = true }
        .fullScreenCover(isPresented: $showingLog) { LogMeditationSheet(initialDate: loggerDate) }
        .onAppear(perform: openPendingLogger)
        .onChange(of: router.pendingLogger) { openPendingLogger() }
    }

    private func openPendingLogger() {
        guard router.pendingLogger == .meditation else { return }
        router.pendingLogger = nil
        loggerDate = router.pendingLoggerDate
        router.pendingLoggerDate = nil
        showingLog = true
    }
}

/// Log a session done elsewhere: when, how long (default 15) and an optional kind.
struct LogMeditationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var when: Date
    @State private var minutes: Int? = 15
    @State private var kind: MeditationKind?

    /// `initialDate` pre-fills When (a past day picked on Today); nil means now.
    init(initialDate: Date? = nil) {
        _when = State(initialValue: initialDate ?? .now)
    }

    var body: some View {
        SheetScaffold {
            SheetHeader(title: "Log meditation") { dismiss() }
        } content: {
            SheetPrompt(text: "Sat today? Log it here. Use whatever app or timer you like.")
            WhenRow(date: $when)
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(title: "How long?")
                DotSelector(values: [5, 10, 15, 20, 30], selection: $minutes, color: Practice.meditation.color)
            }
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(title: "Kind", trailing: "optional")
                FlowLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(MeditationKind.allCases) { option in
                        Chip(title: option.chipLabel, selected: kind == option, accent: Practice.meditation.color) {
                            kind = kind == option ? nil : option
                        }
                    }
                }
            }
        } footer: {
            let value = minutes ?? 15
            PrimaryButton(title: "Log \(value >= 30 ? "30+" : "\(value)") minutes", color: Practice.meditation.color) {
                context.insert(MeditationLog(loggedAt: when, minutes: value, kind: kind))
                try? context.save()
                dismiss()
            }
        }
    }
}

#Preview {
    MeditationView()
        .environment(AppRouter())
        .modelContainer(SampleData.previewContainer)
        .preferredColorScheme(.dark)
}
