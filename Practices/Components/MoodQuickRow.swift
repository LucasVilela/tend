import SwiftUI

/// Today's mood row: status on the left, four quick faces and a dashed "all moods" blob on the right.
struct MoodQuickRow: View {
    let status: String
    let faces: [MoodKind]
    let selected: MoodKind?
    var onOpenMood: () -> Void
    var onPick: (MoodKind) -> Void

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onOpenMood) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mood")
                        .textStyle(Theme.Font.body)
                        .foregroundStyle(Theme.textPrimary)
                    Text(status)
                        .textStyle(Theme.Font.caption)
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, minHeight: Tokens.Spacing.rowMinHeight - 6, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mood, \(status)")
            .accessibilityHint("Opens Mood")

            HStack(spacing: 0) {
                ForEach(faces) { mood in
                    let isOn = mood == selected
                    Button { onPick(mood) } label: {
                        MoodFace(kind: mood, size: Tokens.MoodFace.todayRow, selected: isOn, selectedScale: 1.12)
                            .opacity(selected != nil && !isOn ? Tokens.MoodFace.todayRowUnselectedOpacity : 1)
                            .frame(width: 40, height: 48)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Log mood: \(mood.name)")
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                    .animation(.easeOut(duration: 0.2), value: selected)
                }
                Button(action: onOpenMood) {
                    ZStack {
                        OrganicShape.blob.strokeBorder(Theme.outlineStrong, style: StrokeStyle(lineWidth: 1.25, dash: [3, 2.5]))
                        IconView(icon: .plus, size: 14, lineWidth: 1.5)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .frame(width: 28, height: 28)
                    .frame(width: 40, height: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("All moods")
            }
            .padding(.trailing, -10)
        }
    }
}
