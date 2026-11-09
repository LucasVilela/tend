import SwiftUI

extension View {
    /// Puts a wavy separator under the view (the design's row hairline).
    func waveBelow() -> some View {
        VStack(spacing: 0) {
            self
            WaveDivider()
        }
    }
}

/// A practice row on Today: name over status, with the check face on the right.
struct CheckOffRow: View {
    let practice: Practice
    let status: DayStatus
    let statusLine: String
    var wobbleDelay: Double = 0
    var onOpen: () -> Void
    var onToggle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(practice.name)
                        .textStyle(Theme.Font.body)
                        .foregroundStyle(Theme.textPrimary)
                    Text(statusLine)
                        .textStyle(Theme.Font.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
                .frame(maxWidth: .infinity, minHeight: Tokens.Spacing.rowMinHeight - 6, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(practice.name), \(statusLine)")
            .accessibilityHint("Opens \(practice.name)")

            Button(action: onToggle) {
                CheckFace(practice: practice, status: status, wobbleDelay: wobbleDelay)
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, -10)
            .accessibilityLabel(status == .done ? "\(practice.name) done today. Tap to undo." : "Check off \(practice.name.lowercased()) for today")
            .accessibilityAddTraits(status == .done ? .isSelected : [])
        }
    }
}
