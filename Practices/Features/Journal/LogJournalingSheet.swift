import SwiftData
import SwiftUI

/// Log journaling done elsewhere: when, an optional mood (also saved as a mood check-in) and how long.
struct LogJournalingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var when: Date
    @State private var mood: MoodKind?
    @State private var minutes: Int?

    /// `initialDate` pre-fills When (a past day picked on Today); nil means now.
    init(initialDate: Date? = nil) {
        _when = State(initialValue: initialDate ?? .now)
    }

    var body: some View {
        SheetScaffold {
            SheetHeader(title: "Log journaling") { dismiss() }
        } content: {
            SheetPrompt(text: "Wrote today? Log it here. Your words stay wherever you keep them.")
            WhenRow(date: $when)
            VStack(alignment: .leading, spacing: 16) {
                SectionLabel(title: "How do you feel?", trailing: "optional")
                MoodScrollRow(selection: $mood)
            }
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(title: "How long?", trailing: "optional")
                DotSelector(values: [5, 10, 15, 20, 30], selection: $minutes, color: Practice.journal.color,
                            numberSize: 16, optional: true)
            }
        } footer: {
            PrimaryButton(title: "Log journaling", color: Practice.journal.color, action: save)
        }
    }

    private func save() {
        context.insert(JournalLog(loggedAt: when, mood: mood, minutes: minutes))
        if let mood { context.insert(MoodLog(loggedAt: when, moods: [mood])) }
        try? context.save()
        dismiss()
    }
}

/// All 12 faces in a horizontal row (38 pt in 64 pt buttons); one can be picked, tap again to clear.
struct MoodScrollRow: View {
    @Binding var selection: MoodKind?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(MoodKind.allCases) { mood in
                    let isOn = selection == mood
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selection = isOn ? nil : mood }
                    } label: {
                        VStack(spacing: 8) {
                            MoodFace(kind: mood, size: Tokens.MoodFace.logJournalingRow, selected: isOn)
                            Text(mood.name)
                                .textStyle(Theme.Font.micro)
                                .foregroundStyle(isOn ? Theme.textPrimary : Theme.textTertiary)
                                .lineLimit(1)
                                .fixedSize()
                        }
                        .frame(width: 66)
                        .padding(.vertical, 6)
                        .opacity(selection != nil && !isOn ? Tokens.MoodFace.logJournalingUnselectedOpacity : 1)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(isOn ? "\(mood.name), selected" : mood.name)
                    .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
                }
            }
            .padding(.horizontal, Theme.screenPadding - 1)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -Theme.screenPadding)
    }
}

#Preview {
    LogJournalingSheet()
        .modelContainer(SampleData.previewContainer)
}
