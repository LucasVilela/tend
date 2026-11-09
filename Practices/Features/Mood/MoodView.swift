import SwiftData
import SwiftUI

/// Mood: a big face for how you've mostly been feeling, a 12-face picker (up to 3), the pattern
/// line, and past check-ins. No charts or scores.
struct MoodView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MoodLog.loggedAt, order: .reverse) private var moodLogs: [MoodLog]

    @State private var picked: [MoodKind] = []
    @State private var note = ""

    private let moodStats = MoodStatsService()

    var body: some View {
        DayStatsReader { stats in
            let checkIns = moodLogs.map(MoodCheckIn.init)
            let patterns = moodStats.patterns(checkIns, now: .now) { stats.status($0, on: $1) }
            List {
                Group {
                    PushedHeader(title: "Mood")
                        .padding(.top, 8)
                    LatelyFace(dominant: moodStats.dominant(checkIns))
                        .padding(.top, 20)
                    picker
                        .padding(.top, 32)
                    if !picked.isEmpty {
                        logForm.padding(.top, 24)
                    }
                    if !patterns.isEmpty {
                        PatternText(lines: patterns).padding(.top, 32)
                    }
                    if !moodLogs.isEmpty {
                        SectionLabel(title: "Check-ins").padding(.top, 36).padding(.bottom, 8)
                    }
                }
                .moodListRow()

                ForEach(moodLogs) { log in
                    CheckInRow(log: log)
                        .waveBelow()
                        .moodListRow()
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation { context.delete(log); try? context.save() }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                Color.clear.frame(height: 24).moodListRow()
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 1)
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Picker

    private var picker: some View {
        let max = Tokens.MoodFace.maxMoodsPerCheckIn
        return VStack(alignment: .leading, spacing: 20) {
            SectionLabel(title: "How are you feeling?", trailing: picked.isEmpty ? "Pick up to \(max)" : "\(picked.count) of \(max)")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 4), spacing: 18) {
                ForEach(MoodKind.allCases) { mood in
                    let isOn = picked.contains(mood)
                    let full = picked.count >= max && !isOn
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if isOn { picked.removeAll { $0 == mood } } else if !full { picked.append(mood) }
                        }
                    } label: {
                        VStack(spacing: 8) {
                            MoodFace(kind: mood, size: Tokens.MoodFace.moodPicker, selected: isOn)
                            Text(mood.name)
                                .textStyle(Theme.Font.micro)
                                .foregroundStyle(isOn ? Theme.textPrimary : Theme.textTertiary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 72)
                        .contentShape(Rectangle())
                        .opacity(full ? Tokens.MoodFace.pickerWhenFullOpacity : 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(full)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(isOn ? "\(mood.name), selected" : mood.name)
                    .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
                }
            }
        }
    }

    private var logForm: some View {
        VStack(spacing: 24) {
            UnderlinedField(placeholder: "Add a note (optional)", text: $note,
                            style: Theme.Font.body, accent: Theme.mood, lineLimit: 1...3)
            PrimaryButton(title: "Log " + picked.map(\.name).joined(separator: " + "), color: Theme.mood) {
                let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
                withAnimation(.easeInOut(duration: 0.3)) {
                    context.insert(MoodLog(loggedAt: .now, moods: picked, note: trimmed.isEmpty ? nil : trimmed))
                    try? context.save()
                    picked = []
                    note = ""
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

// MARK: - Lately face

/// The dominant recent mood at 168 pt with a soft glow; wobbles, bobs and bounces when it changes.
private struct LatelyFace: View {
    let dominant: DominantMood?
    @State private var bounce = 0

    var body: some View {
        let mood = dominant?.mood ?? .calm
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(mood.color.opacity(0.25))
                    .frame(width: 240, height: 240)
                    .blur(radius: 64)
                MotionClock { time in
                    MoodFace(kind: mood, size: Tokens.MoodFace.moodHero, large: true,
                             shape: .blob(Loop.radii(Tokens.Shape.blobMorph, time: time, period: Tokens.Motion.buddyWobbleSeconds)))
                        .offset(y: Loop.bob(time, period: 5.8, delay: 0, amplitude: Tokens.Motion.buddyBobPoints))
                }
                .squashBounce(trigger: bounce)
            }
            .frame(height: 200)
            .opacity(dominant == nil ? 0.4 : 1)
            .animation(.easeInOut(duration: 0.6), value: mood)

            VStack(spacing: 4) {
                if let dominant {
                    Text("Lately you're mostly")
                        .textStyle(Theme.Font.secondary)
                        .foregroundStyle(Theme.textTertiary)
                    Text(dominant.mood.name)
                        .textStyle(Theme.Font.display)
                        .foregroundStyle(dominant.mood.color)
                        .contentTransition(.opacity)
                    if let runner = dominant.runnerUp {
                        Text("with some \(Text(runner.name).foregroundStyle(runner.color))")
                            .textStyle(Theme.Font.bodyLong.with(size: 15, lineHeight: 20))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Text("From your last 5 check-ins · the newest count most")
                        .textStyle(Theme.Font.micro)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.top, 12)
                } else {
                    Text("No check-ins yet")
                        .textStyle(Theme.Font.bodyLong.with(size: 15, lineHeight: 20))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.top, 12)
            .animation(.easeInOut(duration: 0.6), value: mood)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .onChange(of: dominant?.mood) { old, new in
            if old != nil, new != old { bounce += 1 }
        }
    }

    private var label: String {
        guard let dominant else { return "No check-ins yet" }
        let extra = dominant.runnerUp.map { ", with some \($0.name)" } ?? ""
        return "Lately you're mostly \(dominant.mood.name)\(extra)"
    }
}

// MARK: - Pattern line and rows

/// Observations with the mood names in their colours.
struct PatternText: View {
    let lines: [PatternLine]

    var body: some View {
        Text(attributed)
            .textStyle(Theme.Font.bodyLong, monospacedDigits: false)
            .foregroundStyle(Theme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var attributed: AttributedString {
        var result = AttributedString()
        for (index, line) in lines.enumerated() {
            if index > 0 { result += AttributedString(" ") }
            for segment in line.segments {
                switch segment {
                case .text(let s):
                    result += AttributedString(s)
                case .mood(let mood):
                    var name = AttributedString(mood.name)
                    name.foregroundColor = mood.color
                    result += name
                }
            }
        }
        return result
    }
}

private struct CheckInRow: View {
    let log: MoodLog

    var body: some View {
        let moods = log.moods
        let detail = [Formats.dayAndTime(log.loggedAt), log.note].compactMap { $0 }.joined(separator: " · ")
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(moods.map(\.name).joined(separator: " + "))
                    .textStyle(Theme.Font.body)
                    .foregroundStyle(Theme.textPrimary)
                Text(detail)
                    .textStyle(Theme.Font.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            MoodStack(moods: moods)
        }
        .frame(minHeight: Tokens.Spacing.listRowMinHeight - 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([moods.map(\.name).joined(separator: " and "), Formats.dayAndTime(log.loggedAt).replacingOccurrences(of: " · ", with: " "), log.note]
            .compactMap { $0 }.joined(separator: ", "))
    }
}

private extension View {
    func moodListRow() -> some View {
        listRowInsets(EdgeInsets(top: 0, leading: Theme.screenPadding, bottom: 0, trailing: Theme.screenPadding))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

#Preview {
    NavigationStack { MoodView() }
        .modelContainer(SampleData.previewContainer)
        .preferredColorScheme(.dark)
}
