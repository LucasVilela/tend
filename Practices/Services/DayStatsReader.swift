import SwiftData
import SwiftUI

/// Queries everything the day rules need and hands the content a ready `DayStatsService`.
/// Screens that show streaks, statuses or totals wrap their body in this.
struct DayStatsReader<Content: View>: View {
    @Query private var journalLogs: [JournalLog]
    @Query private var guidedEntries: [GuidedEntry]
    @Query private var meditations: [MeditationLog]
    @Query private var workouts: [Workout]
    @Query private var checks: [DailyCheck]
    @AppStorage("meditationGoalMinutes") private var meditationGoal = Tokens.Defaults.meditationMinutesPerDay
    @AppStorage("exerciseGoalMinutes") private var exerciseGoal = Tokens.Defaults.exerciseMinutesPerDay

    @ViewBuilder var content: (DayStatsService) -> Content

    var body: some View {
        content(DayStatsService(
            snapshot: ActivitySnapshot(journalLogs: journalLogs, guidedEntries: guidedEntries,
                                       meditations: meditations, workouts: workouts, checks: checks),
            goals: Goals(meditationMinutes: meditationGoal, exerciseMinutes: exerciseGoal)
        ))
    }
}

/// A pushed screen's top: "‹ Today" and the title.
struct PushedHeader: View {
    let title: String
    var back = "Today"

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            BackButton(title: back)
            ScreenTitle(title: title)
        }
    }
}
