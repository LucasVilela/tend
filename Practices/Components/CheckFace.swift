import SwiftUI

/// Today's check button: a 34 pt wobbling blob with a face instead of a check mark.
/// Not started: dashed, sleepy. Started: solid outline, meditating. Done: filled, happy.
struct CheckFace: View {
    let practice: Practice
    let status: DayStatus
    /// Staggers the wobble between the three rows.
    var wobbleDelay: Double = 0

    private var faceStrokes: (eyes: String, mouth: String) {
        switch status {
        case .done: ("M8 8.2v2M14 8.2v2", "M7.3 12.8Q11 16.6 14.7 12.8")
        case .partial: ("M6.4 9.2Q8 10.8 9.6 9.2M12.4 9.2Q14 10.8 15.6 9.2", "M9.2 13.6Q11 15 12.8 13.6")
        case .none: ("M6.4 9.8h3.2M12.4 9.8h3.2", "M10.1 14.3h1.8")
        }
    }

    var body: some View {
        let size = Tokens.Shape.checkFaceSize
        let ink = status == .done ? Theme.onAccent : practice.color
        let border = status == .none ? practice.color.opacity(Theme.partialOpacity) : practice.color
        WobblingBlob(delay: wobbleDelay) { shape in
            ZStack {
                shape.fill(status == .done ? practice.color : .clear)
                shape.strokeBorder(border, style: StrokeStyle(lineWidth: 1.5, dash: status == .none ? [3.5, 3] : []))
                ZStack {
                    SVGShape(data: faceStrokes.eyes, viewBox: 22)
                        .stroke(ink, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                    SVGShape(data: faceStrokes.mouth, viewBox: 22)
                        .stroke(ink, style: StrokeStyle(lineWidth: 1.7, lineCap: .round))
                }
                .frame(width: 24, height: 24)
            }
            .frame(width: size, height: size)
        }
        .animation(.easeOut(duration: 0.25), value: status)
    }
}

#Preview {
    HStack(spacing: 20) {
        ForEach(Practice.allCases) { p in
            VStack(spacing: 12) {
                CheckFace(practice: p, status: .none)
                CheckFace(practice: p, status: .partial)
                CheckFace(practice: p, status: .done)
            }
        }
    }
    .padding()
    .background(Theme.background)
}
