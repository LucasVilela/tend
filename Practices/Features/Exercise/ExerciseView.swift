import SwiftData
import SwiftUI

/// Exercise: the last 7 days against a daily goal, plus recent workouts.
struct ExerciseView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var context
    @Query(sort: \Workout.startedAt, order: .reverse) private var workouts: [Workout]
    @AppStorage("exerciseGoalMinutes") private var goal = Tokens.Defaults.exerciseMinutesPerDay
    @State private var showingLog = false
    @State private var loggerDate: Date?

    var body: some View {
        DayStatsReader { stats in
            let now = Date.now
            let cal = Calendar.practices
            let days = cal.days(endingAt: now, count: 7)
            let bars = days.map { MiniBarChart.Bar(day: $0, minutes: stats.minutes(.exercise, on: $0), isToday: cal.isDate($0, inSameDayAs: now)) }
            let weekStart = days.first ?? now
            let week = workouts.filter { $0.startedAt >= weekStart && $0.startedAt <= now }
            let km = week.compactMap(\.distanceKm).reduce(0, +)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ScreenTitle(title: "Exercise")
                    Text("\(goal) minutes a day · \(stats.streak(.exercise, asOf: now))-day streak")
                        .textStyle(Theme.Font.secondary)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.top, 6)

                    SectionLabel(title: "Last 7 days").padding(.top, 36)
                    HStack(alignment: .top, spacing: 0) {
                        stat(durationLabel(bars.map(\.minutes).reduce(0, +)), "active")
                        stat("\(week.count)", week.count == 1 ? "workout" : "workouts")
                        stat(String(format: "%.1f", km), "km")
                    }
                    .padding(.top, 12)

                    MiniBarChart(bars: bars, goal: goal, color: Practice.exercise.color, muted: Practice.exercise.mutedColor, height: 80)
                        .padding(.top, 32)

                    if !workouts.isEmpty {
                        SectionLabel(title: "Recent workouts").padding(.top, 36).padding(.bottom, 8)
                        ForEach(workouts.prefix(30)) { workout in
                            DetailRow(title: workout.title, detail: detail(workout)) {
                                Text("\(workout.durationMinutes) min")
                                    .textStyle(Theme.Font.bodyLong.with(size: 15, lineHeight: 20))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .waveBelow()
                            .contextMenu {
                                Button("Delete", role: .destructive) {
                                    withAnimation { context.delete(workout); try? context.save() }
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
        .floatingAction(color: Practice.exercise.color, label: "Log workout") { loggerDate = nil; showingLog = true }
        .fullScreenCover(isPresented: $showingLog) { LogWorkoutSheet(startedAt: loggerDate) }
        .onAppear(perform: openPendingLogger)
        .onChange(of: router.pendingLogger) { openPendingLogger() }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).textStyle(Theme.Font.statNumber).foregroundStyle(Theme.textPrimary)
            Text(label).textStyle(Theme.Font.caption).foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func detail(_ workout: Workout) -> String {
        var parts = [Formats.relativeDay(workout.startedAt, now: .now), workout.type.name]
        if let km = workout.distanceKm, workout.type.hasDistance { parts.append(String(format: "%.1f km", km)) }
        return parts.joined(separator: " · ")
    }

    private func openPendingLogger() {
        guard router.pendingLogger == .exercise else { return }
        router.pendingLogger = nil
        loggerDate = router.pendingLoggerDate
        router.pendingLoggerDate = nil
        showingLog = true
    }
}

/// Log a workout: type, duration (5–300 in 5s), intensity, distance for runs, walks and rides, notes.
struct LogWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var type: WorkoutType = .run
    @State private var duration = 30
    @State private var intensity: Intensity = .moderate
    @State private var distance = ""
    @State private var notes = ""

    /// A past day picked on Today; nil logs the workout now (the sheet has no When row).
    let startedAt: Date?
    init(startedAt: Date? = nil) { self.startedAt = startedAt }

    private let accent = Practice.exercise.color

    var body: some View {
        SheetScaffold {
            SheetHeader(title: "Log workout") { dismiss() }
        } content: {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(title: "Type")
                FlowLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(WorkoutType.allCases) { option in
                        Chip(title: option.name, selected: type == option, accent: accent) {
                            withAnimation(.easeInOut(duration: 0.2)) { type = option }
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(title: "Duration")
                HStack {
                    stepButton(.minus, "Shorter") { duration = max(5, duration - 5) }
                    Spacer()
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text("\(duration)").textStyle(Theme.Font.displayXL).foregroundStyle(Theme.textPrimary)
                            .contentTransition(.numericText(value: Double(duration)))
                        Text("min").textStyle(Theme.Font.bodyLong.with(size: 15, lineHeight: 20)).foregroundStyle(Theme.textTertiary)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(duration) minutes")
                    .accessibilityAdjustableAction { direction in
                        switch direction {
                        case .increment: duration = min(300, duration + 5)
                        case .decrement: duration = max(5, duration - 5)
                        @unknown default: break
                        }
                    }
                    Spacer()
                    stepButton(.plus, "Longer") { duration = min(300, duration + 5) }
                }
                .animation(.snappy(duration: 0.2), value: duration)
            }
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(title: "Intensity")
                CapsuleSwitch(options: Intensity.allCases, selection: $intensity) { $0.name }
            }
            if type.hasDistance {
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(title: "Distance")
                    HStack(alignment: .lastTextBaseline) {
                        TextField("", text: $distance, prompt: Text("0.0").foregroundStyle(Theme.textTertiary))
                            .keyboardType(.decimalPad)
                            .textStyle(TextStyleToken(size: 24, lineHeight: 30, weight: 300, tracking: 0))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(accent)
                            .accessibilityLabel("Distance in kilometres")
                        Text("km").textStyle(Theme.Font.bodyLong.with(size: 15, lineHeight: 20)).foregroundStyle(Theme.textTertiary)
                    }
                    WaveDivider()
                }
                .transition(.opacity)
            }
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(title: "Notes")
                UnderlinedField(placeholder: "How did it feel?", text: $notes, accent: accent, lineLimit: 3...8, minHeight: 72)
            }
        } footer: {
            PrimaryButton(title: "Save workout", icon: nil, color: accent, action: save)
        }
    }

    private func stepButton(_ icon: Icon, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            IconView(icon: icon, size: 20, lineWidth: 1.5)
                .foregroundStyle(Theme.textPrimary)
                .frame(width: Tokens.Shape.stepperButtonSize, height: Tokens.Shape.stepperButtonSize)
                .background(OrganicShape.blob.strokeBorder(Theme.outline, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func save() {
        let now = startedAt ?? .now
        let km = Double(distance.replacingOccurrences(of: ",", with: "."))
        context.insert(Workout(
            startedAt: now,
            title: WorkoutTitle.make(type: type, intensity: intensity, at: now),
            type: type,
            durationMinutes: duration,
            intensity: intensity,
            distanceKm: type.hasDistance ? km.flatMap { $0 > 0 ? $0 : nil } : nil,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
        try? context.save()
        dismiss()
    }
}

#Preview {
    ExerciseView()
        .environment(AppRouter())
        .modelContainer(SampleData.previewContainer)
        .preferredColorScheme(.dark)
}
