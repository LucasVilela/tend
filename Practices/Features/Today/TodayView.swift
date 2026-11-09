import SwiftData
import SwiftUI

/// Today: greeting, the week, the three buddies, one-tap check-offs and quick mood.
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppRouter.self) private var router

    @Query private var journalLogs: [JournalLog]
    @Query private var guidedEntries: [GuidedEntry]
    @Query private var meditations: [MeditationLog]
    @Query private var workouts: [Workout]
    @Query private var checks: [DailyCheck]
    @Query(sort: \MoodLog.loggedAt, order: .reverse) private var moodLogs: [MoodLog]

    @AppStorage("firstName") private var firstName = ""
    @AppStorage("didAskForName") private var didAskForName = false
    @AppStorage("meditationGoalMinutes") private var meditationGoal = Tokens.Defaults.meditationMinutesPerDay
    @AppStorage("exerciseGoalMinutes") private var exerciseGoal = Tokens.Defaults.exerciseMinutesPerDay

    @State private var askingForName = false
    @State private var nameDraft = ""

    private let calendar = Calendar.practices

    var body: some View {
        TimelineView(.everyMinute) { context in
            content(now: context.date)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if !didAskForName && firstName.isEmpty { askingForName = true }
        }
        .alert("What should we call you?", isPresented: $askingForName) {
            TextField("First name", text: $nameDraft)
                .textContentType(.givenName)
            Button("Skip", role: .cancel) { didAskForName = true }
            Button("Save") {
                firstName = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                didAskForName = true
            }
        } message: {
            Text("It's only used for the greeting on Today.")
        }
    }

    private func content(now: Date) -> some View {
        let stats = DayStatsService(
            snapshot: ActivitySnapshot(journalLogs: journalLogs, guidedEntries: guidedEntries,
                                       meditations: meditations, workouts: workouts, checks: checks),
            goals: Goals(meditationMinutes: meditationGoal, exerciseMinutes: exerciseGoal),
            calendar: calendar
        )
        let moodStats = MoodStatsService(calendar: calendar)
        let todaysMoods = moodLogs.filter { calendar.isDate($0.loggedAt, inSameDayAs: now) }
        let quickFaces = moodStats.quickFaces(moodLogs.map(MoodCheckIn.init), now: now)
        let latestToday = todaysMoods.first
        let selectedQuick = latestToday.flatMap { log in
            log.moods.count == 1 && quickFaces.contains(log.moods[0]) ? log : nil
        }
        let doneCount = stats.doneCount(on: now)

        return ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header(now: now)

                WeekStrip(days: calendar.days(endingAt: now, count: 7).map { day in
                    WeekStrip.Day(date: day, statuses: stats.statuses(on: day), isToday: calendar.isDate(day, inSameDayAs: now))
                })

                VStack(spacing: 16) {
                    BuddyCluster(
                        states: Dictionary(uniqueKeysWithValues: Practice.allCases.map { p in
                            (p, BuddyCluster.State(fill: stats.fill(p, on: now), status: stats.status(p, on: now),
                                                   statusLine: stats.statusLine(p, now: now)))
                        }),
                        onTap: { toggle($0, stats: stats) },
                        onLongPress: { router.openLogger(for: $0) }
                    )
                    summary(doneCount: doneCount)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 0) {
                    WaveDivider()
                    ForEach(Array(Practice.allCases.enumerated()), id: \.element) { index, practice in
                        CheckOffRow(
                            practice: practice,
                            status: stats.status(practice, on: now),
                            statusLine: stats.statusLine(practice, now: now),
                            wobbleDelay: -3 * Double(index),
                            onOpen: { router.open(practice) },
                            onToggle: { toggle(practice, stats: stats) }
                        )
                        .waveBelow()
                    }
                    MoodQuickRow(
                        status: moodStatus(latestToday, now: now),
                        faces: quickFaces,
                        selected: selectedQuick?.moods.first,
                        onOpenMood: { router.todayPath.append(.mood) },
                        onPick: { mood in
                            withAnimation(.easeOut(duration: 0.2)) {
                                PracticeActions(context: context, calendar: calendar).quickMood(mood, selected: selectedQuick, now: .now)
                            }
                        }
                    )
                    .waveBelow()
                }
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private func header(now: Date) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Formats.longDay(now, calendar: calendar))
                    .textStyle(Theme.Font.secondary)
                    .foregroundStyle(Theme.textTertiary)
                Text(Formats.greeting(at: now, name: firstName, calendar: calendar))
                    .textStyle(Theme.Font.title)
                    .foregroundStyle(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer(minLength: 0)
            Button { router.todayPath.append(.insights) } label: {
                IconView(icon: .chart, size: 22, lineWidth: 1.5)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, -8)
            .padding(.trailing, -10)
            .accessibilityLabel("Insights")
        }
    }

    private func summary(doneCount: Int) -> some View {
        let count = Text("\(doneCount) of 3").foregroundStyle(Theme.textPrimary)
        let rest = Text(doneCount == 3 ? " lit. Party in the middle!" : " complete · tap to check off")
            .foregroundStyle(Theme.textTertiary)
        return Text("\(count)\(rest)")
            .textStyle(Theme.Font.secondary)
            .multilineTextAlignment(.center)
            .contentTransition(.numericText())
    }

    private func moodStatus(_ latest: MoodLog?, now: Date) -> String {
        guard let latest else { return "How are you feeling?" }
        let names = latest.moods.map(\.name).joined(separator: " + ")
        let when = now.timeIntervalSince(latest.loggedAt) < 60 ? "just now" : Formats.time(latest.loggedAt, calendar: calendar)
        return "\(names) · \(when)"
    }

    private func toggle(_ practice: Practice, stats: DayStatsService) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            _ = PracticeActions(context: context, calendar: calendar).toggleCheckOff(practice, stats: stats, now: .now)
        }
    }
}

#Preview {
    NavigationStack {
        TodayView()
    }
    .environment(AppRouter())
    .modelContainer(SampleData.previewContainer)
    .preferredColorScheme(.dark)
}
