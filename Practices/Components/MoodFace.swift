import SwiftUI

/// A mood as its face: a blob in the mood's colour with the face art on top.
/// Selected faces get a ring in the face colour with a background-coloured gap, and grow slightly.
struct MoodFace: View {
    let kind: MoodKind
    var size: CGFloat
    var selected: Bool = false
    var selectedScale: CGFloat = Tokens.MoodFace.selectedScale
    /// Use the thin-stroke art made for the big Mood face.
    var large: Bool = false
    var shape: OrganicShape = .blob

    var body: some View {
        ZStack {
            shape.fill(kind.color)
            Image(large ? kind.largeFaceAsset : kind.faceAsset)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
        }
        .frame(width: size, height: size)
        .overlay {
            if selected {
                shape
                    .stroke(kind.color, lineWidth: Tokens.MoodFace.ringWidth)
                    .padding(-(Tokens.MoodFace.ringGap + Tokens.MoodFace.ringWidth / 2))
            }
        }
        .scaleEffect(selected ? selectedScale : 1)
        .accessibilityElement()
        .accessibilityLabel(selected ? "\(kind.name), selected" : kind.name)
        .accessibilityAddTraits(.isImage)
    }
}

/// Faces of one check-in, overlapping by 10 pt, each with a background-coloured outline.
struct MoodStack: View {
    let moods: [MoodKind]
    var size: CGFloat = Tokens.MoodFace.checkInRow
    var overlap: CGFloat = 10

    var body: some View {
        HStack(spacing: -overlap) {
            ForEach(Array(moods.enumerated()), id: \.offset) { index, mood in
                MoodFace(kind: mood, size: size)
                    .background {
                        OrganicShape.blob.fill(Theme.background).padding(-2.5)
                    }
                    .zIndex(Double(moods.count - index))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(moods.map(\.name).joined(separator: " and "))
    }
}

#Preview("Mood faces") {
    ScrollView {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
            ForEach(MoodKind.allCases) { kind in
                VStack(spacing: 8) {
                    MoodFace(kind: kind, size: 44, selected: kind == .calm || kind == .grateful)
                    Text(kind.name).textStyle(Theme.Font.micro).foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(24)
        MoodFace(kind: .calm, size: 168, large: true)
        MoodStack(moods: [.anxious, .badSleep])
    }
    .background(Theme.background)
}
