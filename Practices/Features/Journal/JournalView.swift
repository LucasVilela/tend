import SwiftData
import SwiftUI

/// Journal: a Tracker for journaling done elsewhere, and Guided templates answered in the app.
struct JournalView: View {
    enum Mode: String, CaseIterable { case tracker, guided }

    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var context
    @SceneStorage("journalMode") private var mode: Mode = .tracker

    @Query(sort: \JournalLog.loggedAt, order: .reverse) private var logs: [JournalLog]
    @Query(sort: \GuidedEntry.createdAt, order: .reverse) private var entries: [GuidedEntry]
    @Query(sort: \GuidedTemplate.sortOrder) private var templates: [GuidedTemplate]

    @State private var showingLog = false
    @State private var loggerDate: Date?
    @State private var answering: GuidedTemplate?
    @State private var editing: GuidedEntry?
    @State private var expanded: PersistentIdentifier?

    var body: some View {
        DayStatsReader { stats in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ScreenTitle(title: "Journal")
                    CapsuleSwitch(options: Mode.allCases, selection: $mode) { $0 == .tracker ? "Tracker" : "Guided" }
                        .padding(.top, 20)
                    switch mode {
                    case .tracker: tracker(stats: stats, now: .now)
                    case .guided: guided
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
        }
        .background(Theme.background.ignoresSafeArea())
        .floatingAction(color: Practice.journal.color, label: "Log journaling", visible: mode == .tracker) { loggerDate = nil; showingLog = true }
        .fullScreenCover(isPresented: $showingLog) { LogJournalingSheet(initialDate: loggerDate) }
        .fullScreenCover(item: $answering) { AnswerTemplateSheet(template: $0) }
        .fullScreenCover(item: $editing) { AnswerTemplateSheet(entry: $0) }
        .onAppear(perform: openPendingLogger)
        .onChange(of: router.pendingLogger) { openPendingLogger() }
    }

    private func openPendingLogger() {
        guard router.pendingLogger == .journal else { return }
        router.pendingLogger = nil
        loggerDate = router.pendingLoggerDate
        router.pendingLoggerDate = nil
        mode = .tracker
        showingLog = true
    }

    // MARK: Tracker

    private func tracker(stats: DayStatsService, now: Date) -> some View {
        let first = stats.firstJournalTime(on: now)
        let month = stats.doneDays(.journal, inMonthOf: now, now: now)
        return VStack(alignment: .leading, spacing: 0) {
            Text(first.map { "Once a day · journaled today at \(Formats.time($0))" } ?? "Once a day · not yet today")
                .textStyle(Theme.Font.secondary)
                .foregroundStyle(Theme.textTertiary)
                .padding(.top, 20)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(stats.streak(.journal, asOf: now))")
                        .textStyle(Theme.Font.displayXL)
                        .foregroundStyle(Theme.textPrimary)
                    Text("day streak").textStyle(Theme.Font.secondary).foregroundStyle(Theme.textTertiary)
                }
                .accessibilityElement(children: .combine)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(month.done) of \(month.of)")
                        .textStyle(TextStyleToken(size: 20, lineHeight: 26, weight: 300, tracking: 0))
                        .foregroundStyle(Theme.textPrimary)
                    Text("days this month").textStyle(Theme.Font.secondary).foregroundStyle(Theme.textTertiary)
                }
                .accessibilityElement(children: .combine)
            }
            .padding(.top, 36)

            SectionLabel(title: Formats.monthName(now)).padding(.top, 36).padding(.bottom, 14)
            MonthDots(month: now, now: now) { stats.status(.journal, on: $0) == .done }

            let rows = checkInRows
            if !rows.isEmpty {
                SectionLabel(title: "Check-ins").padding(.top, 36).padding(.bottom, 8)
                ForEach(rows) { row in
                    JournalCheckInRow(row: row)
                        .waveBelow()
                        .contextMenu {
                            if let log = row.log {
                                Button("Delete", role: .destructive) {
                                    withAnimation { context.delete(log); try? context.save() }
                                }
                            }
                        }
                }
            }
        }
    }

    /// Journal logs, plus guided entries on days without a log, newest first.
    private var checkInRows: [JournalCheckInRow.Model] {
        let cal = Calendar.practices
        let loggedDays = Set(logs.map { cal.startOfDay(for: $0.loggedAt) })
        let fromLogs = logs.prefix(60).map { JournalCheckInRow.Model(log: $0) }
        let fromEntries = entries.prefix(60)
            .filter { !loggedDays.contains(cal.startOfDay(for: $0.createdAt)) }
            .map { JournalCheckInRow.Model(entry: $0) }
        return (fromLogs + fromEntries).sorted { $0.date > $1.date }
    }

    // MARK: Guided

    private var guided: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(title: "Templates").padding(.top, 28).padding(.bottom, 4)
            ForEach(templates) { template in
                Button { answering = template } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.name).textStyle(Theme.Font.body).foregroundStyle(Theme.textPrimary)
                            Text("\(template.questions.count) questions · \(template.subtitle)")
                                .textStyle(Theme.Font.caption).foregroundStyle(Theme.textTertiary)
                        }
                        Spacer()
                        IconView(icon: .chevronRight, size: 18, lineWidth: 1.5).foregroundStyle(Theme.textTertiary)
                    }
                    .frame(minHeight: Tokens.Spacing.listRowMinHeight - 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityHint("Opens the template to answer")
                .waveBelow()
            }

            if !entries.isEmpty {
                SectionLabel(title: "Your answers").padding(.top, 36).padding(.bottom, 4)
                ForEach(entries) { entry in
                    ExpandableAnswerRow(
                        entry: entry,
                        expanded: expanded == entry.persistentModelID,
                        onToggle: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                expanded = expanded == entry.persistentModelID ? nil : entry.persistentModelID
                            }
                        }
                    )
                    .contextMenu {
                        Button("Edit") { editing = entry }
                        Button("Delete", role: .destructive) {
                            withAnimation { context.delete(entry); try? context.save() }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Rows

private struct JournalCheckInRow: View {
    struct Model: Identifiable {
        let id: PersistentIdentifier
        let date: Date
        let detail: String?
        let mood: MoodKind?
        let log: JournalLog?

        init(log: JournalLog) {
            id = log.persistentModelID
            date = log.loggedAt
            detail = log.minutes.map { $0 >= 30 ? "30+ min" : "\($0) min" }
            mood = log.mood
            self.log = log
        }

        init(entry: GuidedEntry) {
            id = entry.persistentModelID
            date = entry.createdAt
            detail = entry.templateName
            mood = nil
            log = nil
        }
    }

    let row: Model

    var body: some View {
        HStack(spacing: 14) {
            OrganicShape.blob.fill(Practice.journal.color).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(Formats.relativeDay(row.date, now: .now)).textStyle(Theme.Font.body).foregroundStyle(Theme.textPrimary)
                Text([Formats.time(row.date), row.detail].compactMap { $0 }.joined(separator: " · "))
                    .textStyle(Theme.Font.caption).foregroundStyle(Theme.textTertiary)
            }
            Spacer(minLength: 8)
            if let mood = row.mood {
                Text(mood.name).textStyle(Theme.Font.secondary).foregroundStyle(mood.color)
                MoodFace(kind: mood, size: Tokens.MoodFace.journalList)
            }
        }
        .frame(minHeight: Tokens.Spacing.listRowMinHeight - 6)
        .accessibilityElement(children: .combine)
    }
}

/// A stored guided entry that expands in place to show its questions and answers.
struct ExpandableAnswerRow: View {
    let entry: GuidedEntry
    let expanded: Bool
    var onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 14) {
                    OrganicShape.blob.fill(Practice.journal.color).frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.templateName).textStyle(Theme.Font.body).foregroundStyle(Theme.textPrimary)
                        Text(Formats.dateAndTime(entry.createdAt)).textStyle(Theme.Font.caption).foregroundStyle(Theme.textTertiary)
                    }
                    Spacer()
                    IconView(icon: .chevronRight, size: 18, lineWidth: 1.5)
                        .foregroundStyle(Theme.textTertiary)
                        .rotationEffect(.degrees(expanded ? -90 : 90))
                }
                .frame(minHeight: Tokens.Spacing.listRowMinHeight - 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityValue(expanded ? "Expanded" : "Collapsed")
            .accessibilityAddTraits(.isButton)

            if expanded {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(entry.orderedAnswers.filter { !$0.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { answer in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(answer.question).textStyle(Theme.Font.caption).foregroundStyle(Theme.textTertiary)
                            Text(answer.answer)
                                .textStyle(Theme.Font.bodyLong, monospacedDigits: false)
                                .foregroundStyle(Theme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.leading, 22)
                .padding(.bottom, 20)
                .transition(.opacity)
            }
            WaveDivider()
        }
    }
}

#Preview {
    JournalView()
        .environment(AppRouter())
        .modelContainer(SampleData.previewContainer)
        .preferredColorScheme(.dark)
}
