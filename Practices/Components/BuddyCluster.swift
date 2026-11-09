import SwiftUI

/// The three blob buddies on Today: overlapping like a Venn diagram, each filling with liquid as its
/// practice progresses. Tap to check off, long-press for the detailed logger. When all three are
/// full, the centre sparkle becomes a twinkling gold star with a burst of confetti.
struct BuddyCluster: View {
    struct State: Equatable {
        var fill: Double
        var status: DayStatus
        var statusLine: String
    }

    let states: [Practice: State]
    var onTap: (Practice) -> Void
    var onLongPress: (Practice) -> Void

    @SwiftUI.State private var bounces: [Practice: Int] = [:]
    @SwiftUI.State private var confettiBursts = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var allLit: Bool { Practice.allCases.allSatisfy { states[$0]?.status == .done } }

    /// Layout and timing per buddy, from the design (top-left corners in a 240 × 228 area).
    fileprivate struct Placement {
        let origin: CGPoint
        let face: CGPoint
        let delay: Double
        let bobSeconds: Double
        let tintOpacity: Double
    }

    fileprivate static let placements: [Practice: Placement] = [
        .journal: Placement(origin: CGPoint(x: 10, y: 12), face: CGPoint(x: 20, y: 44), delay: 0, bobSeconds: 5.4, tintOpacity: 0.08),
        .meditation: Placement(origin: CGPoint(x: 102, y: 12), face: CGPoint(x: 62, y: 54), delay: -2, bobSeconds: 6.1, tintOpacity: 0.08),
        .exercise: Placement(origin: CGPoint(x: 66, y: 92), face: CGPoint(x: 42, y: 72), delay: -4, bobSeconds: 5.8, tintOpacity: 0.06),
    ]

    static let size = CGSize(width: 240, height: 228)
    static let buddySize: CGFloat = 128

    var body: some View {
        MotionClock { time in
            ZStack(alignment: .topLeading) {
                ForEach(Practice.allCases) { practice in
                    let placement = Self.placements[practice]!
                    BuddyView(
                        practice: practice,
                        state: states[practice] ?? State(fill: 0, status: .none, statusLine: ""),
                        placement: placement,
                        time: time,
                        bounce: bounces[practice, default: 0]
                    )
                    .offset(x: placement.origin.x, y: placement.origin.y)
                    .onTapGesture {
                        bounces[practice, default: 0] += 1
                        onTap(practice)
                    }
                    .onLongPressGesture(minimumDuration: 0.5) { onLongPress(practice) }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(practice.name): \(states[practice]?.statusLine ?? "")")
                    .accessibilityHint("Double-tap to check off. Use actions to log details.")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { onTap(practice) }
                    .accessibilityAction(named: "Log details") { onLongPress(practice) }
                }
                Sparkle(lit: allLit, time: time)
                    .frame(width: 20, height: 20)
                    .offset(x: 113, y: 93)
                    .allowsHitTesting(false)
                if confettiBursts > 0 && !reduceMotion {
                    ConfettiBurst()
                        .id(confettiBursts)
                        .offset(x: 123, y: 103)
                        .allowsHitTesting(false)
                }
            }
            .compositingGroup()
            .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: bounces)
        .sensoryFeedback(.success, trigger: confettiBursts)
        .onChange(of: allLit) { _, lit in
            if lit { confettiBursts += 1 }
        }
    }
}

// MARK: - One buddy

private struct BuddyView: View {
    let practice: Practice
    let state: BuddyCluster.State
    let placement: BuddyCluster.Placement
    let time: TimeInterval
    let bounce: Int

    /// The buddies' own three-shape morph (Main.dc.html `morph` keyframes).
    static let morph: [CornerRadii] = [
        CornerRadii(0.44, 0.56, 0.54, 0.46, 0.50, 0.44, 0.56, 0.50),
        CornerRadii(0.56, 0.44, 0.46, 0.54, 0.56, 0.56, 0.44, 0.44),
        CornerRadii(0.50, 0.50, 0.58, 0.42, 0.44, 0.54, 0.46, 0.56),
    ]

    var body: some View {
        let color = practice.buddyColor
        let shape = OrganicShape.blob(Loop.radii(Self.morph, time: time, period: Tokens.Motion.buddyWobbleSeconds, delay: placement.delay))
        let started = state.fill > 0
        let wavePhase = Loop.progress(time, period: Tokens.Motion.waveSeconds, delay: placement.delay) * Tokens.Motion.wavePeriod * 2

        ZStack(alignment: .topLeading) {
            shape.fill(started ? .clear : color.opacity(placement.tintOpacity))
            LiquidShape(level: state.fill, phase: wavePhase)
                .fill(color)
                .animation(.spring(response: 1.0, dampingFraction: 0.55), value: state.fill)
                .clipShape(shape)
            shape.strokeBorder(color, style: StrokeStyle(lineWidth: 2, dash: started ? [] : [5, 4]))
            BuddyFace(status: state.status, ink: started ? Theme.ink : color, time: time, delay: placement.delay)
                .frame(width: 44, height: 30, alignment: .topLeading)
                .offset(x: placement.face.x, y: placement.face.y)
        }
        .frame(width: BuddyCluster.buddySize, height: BuddyCluster.buddySize)
        // Flatten face over fill first, so only the whole buddy screens against its neighbours.
        .compositingGroup()
        .contentShape(shape)
        .offset(y: Loop.bob(time, period: placement.bobSeconds, delay: placement.delay, amplitude: Tokens.Motion.buddyBobPoints))
        .keyframeAnimator(initialValue: CGSize(width: 1, height: 1), trigger: bounce) { content, scale in
            content.scaleEffect(x: scale.width, y: scale.height)
        } keyframes: { _ in
            let frames = Tokens.Motion.tapBounceKeyframes
            let total = Tokens.Motion.tapBounceSeconds
            KeyframeTrack(\.self) {
                CubicKeyframe(frames[1], duration: total * 0.28)
                CubicKeyframe(frames[2], duration: total * 0.24)
                CubicKeyframe(frames[3], duration: total * 0.22)
                CubicKeyframe(frames[4], duration: total * 0.26)
            }
        }
        .blendMode(.screen)
    }
}

/// Liquid filling the buddy to `level` (0…1) with a scrolling sine-wave surface.
private struct LiquidShape: Shape {
    var level: Double
    var phase: Double

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let surface = rect.maxY - rect.height * CGFloat(min(max(level, 0), 1)) - 4
        let amplitude = Tokens.Motion.waveAmplitude / 2
        let period = Tokens.Motion.wavePeriod
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        var x = rect.minX
        while x <= rect.maxX {
            let y = surface - amplitude * sin((x + phase) / period * 2 * .pi)
            p.addLine(to: CGPoint(x: x, y: min(y, rect.maxY + 6)))
            x += 2
        }
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Faces in the open part of each buddy: sleepy (empty), meditating (started), happy (full).
private struct BuddyFace: View {
    let status: DayStatus
    let ink: Color
    let time: TimeInterval
    let delay: Double

    var body: some View {
        ZStack(alignment: .topLeading) {
            switch status {
            case .done: happy
            case .partial: meditating
            case .none: sleepy
            }
        }
        .accessibilityHidden(true)
    }

    private var happy: some View {
        // Blink: eyes squash at 94% of a 4.6 s loop.
        let p = Loop.progress(time, period: 4.6, delay: delay)
        let blink: CGFloat = p < 0.9 ? 1 : p < 0.94 ? 1 - 0.9 * CGFloat((p - 0.9) / 0.04) : 0.1 + 0.9 * CGFloat((p - 0.94) / 0.06)
        return ZStack(alignment: .topLeading) {
            ForEach([10.0, 28.0], id: \.self) { x in
                RoundedRectangle(cornerRadius: 3).fill(ink)
                    .frame(width: 6, height: 9)
                    .scaleEffect(x: 1, y: blink)
                    .offset(x: x, y: 2)
            }
            ForEach([1.0, 34.0], id: \.self) { x in
                Ellipse().fill(Theme.cheek.opacity(0.5)).frame(width: 9, height: 5).offset(x: x, y: 14)
            }
            SVGShape(data: "M2 2Q8 10 14 2", viewBox: 16)
                .stroke(ink, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 16, height: 10)
                .offset(x: 14, y: 13)
        }
    }

    private var meditating: some View {
        ZStack(alignment: .topLeading) {
            ForEach([7.0, 26.0], id: \.self) { x in
                SVGShape(data: "M1.5 1.5Q5.5 6.5 9.5 1.5", viewBox: 11)
                    .stroke(ink, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 11, height: 7)
                    .offset(x: x, y: 4)
            }
            SVGShape(data: "M1.5 1.5Q5 5 8.5 1.5", viewBox: 10)
                .stroke(ink, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                .frame(width: 10, height: 6)
                .offset(x: 17, y: 16)
        }
    }

    private var sleepy: some View {
        ZStack(alignment: .topLeading) {
            ForEach([7.0, 27.0], id: \.self) { x in
                RoundedRectangle(cornerRadius: 1).fill(ink).frame(width: 10, height: 2).offset(x: x, y: 7)
            }
            Circle().strokeBorder(ink, lineWidth: 1.5).frame(width: 6, height: 6).offset(x: 19, y: 15)
            ForEach(0..<3, id: \.self) { i in
                // Floating z's: 3 s loop each, a second apart.
                let p = Loop.progress(time, period: 3, delay: Double(i))
                let eased = 1 - pow(1 - p, 2)
                Text("z")
                    .font(ThemeFonts.font(Theme.Font.micro.with(size: CGFloat(11 + 2 * i)).with(weight: 600)))
                    .foregroundStyle(ink)
                    .scaleEffect(0.6 + 0.55 * eased, anchor: .bottomLeading)
                    .opacity(p < 0.25 ? p / 0.25 : 1 - (p - 0.25) / 0.75)
                    .offset(x: 40 + 12 * eased, y: -6 - 26 * eased)
            }
        }
    }
}

// MARK: - Sparkle and confetti

private struct Sparkle: View {
    let lit: Bool
    let time: TimeInterval

    private static let star = "M10 0C10.8 6.5 13.5 9.2 20 10C13.5 10.8 10.8 13.5 10 20C9.2 13.5 6.5 10.8 0 10C6.5 9.2 9.2 6.5 10 0Z"

    var body: some View {
        if lit {
            let p = Loop.progress(time, period: 1.8)
            let wave = 0.5 - 0.5 * cos(p * 2 * .pi)
            ZStack {
                SVGShape(data: Self.star, viewBox: 20).fill(Theme.sparkleGold)
                SVGShape(data: Self.star, viewBox: 20).stroke(Theme.ink, style: StrokeStyle(lineWidth: 0.8, lineJoin: .round))
            }
            .frame(width: 25, height: 25)
            .shadow(color: Theme.sparkleGold.opacity(0.9), radius: 8)
            .scaleEffect(0.8 + 0.45 * wave)
            .rotationEffect(.degrees(45 * wave))
            .frame(width: 20, height: 20)
            .transition(.scale.combined(with: .opacity))
        } else {
            SVGShape(data: Self.star, viewBox: 20)
                .fill(Theme.sparkleDim)
                .frame(width: 10, height: 10)
        }
    }
}

/// 16 pieces flying out from the centre once (1.3 s).
private struct ConfettiBurst: View {
    @State private var progress: CGFloat = 0

    private struct Piece {
        let angle: Double
        let distance: CGFloat
        let spin: Double
        let color: Color
        let size: CGSize
        let isDot: Bool
        let delay: Double
    }

    private static let pieces: [Piece] = (0..<Tokens.Motion.confettiPieces).map { i in
        let colors = [Practice.journal.buddyColor, Practice.meditation.buddyColor, Practice.exercise.buddyColor, Theme.textPrimary]
        let distances = [Tokens.Motion.confettiDistance[0], 94, Tokens.Motion.confettiDistance[1]]
        return Piece(
            angle: Double(i) * 22.5 + (i % 2 == 1 ? 8 : -6),
            distance: distances[i % 3],
            spin: [220, -200, 260][i % 3],
            color: colors[i % 4],
            size: i % 3 == 0 ? CGSize(width: 8, height: 4) : CGSize(width: 6, height: 6),
            isDot: i % 3 != 0,
            delay: Double(i % 5) * 0.03
        )
    }

    var body: some View {
        ZStack {
            ForEach(Array(Self.pieces.enumerated()), id: \.offset) { _, piece in
                Group {
                    if piece.isDot {
                        OrganicShape.blob.fill(piece.color)
                    } else {
                        RoundedRectangle(cornerRadius: 1).fill(piece.color)
                    }
                }
                .frame(width: piece.size.width, height: piece.size.height)
                .rotationEffect(.degrees(piece.spin * progress))
                .scaleEffect(1 - 0.7 * progress)
                .offset(x: piece.distance * progress)
                .rotationEffect(.degrees(piece.angle))
                .opacity(1 - progress)
                .animation(.timingCurve(0.15, 0.7, 0.3, 1, duration: Tokens.Motion.confettiSeconds).delay(piece.delay), value: progress)
            }
        }
        .frame(width: 0, height: 0)
        .onAppear { progress = 1 }
    }
}

#Preview("Buddies") {
    struct Demo: View {
        @State var fills: [Practice: Double] = [.journal: 1, .meditation: 2 / 3, .exercise: 0]
        var body: some View {
            BuddyCluster(
                states: Dictionary(uniqueKeysWithValues: Practice.allCases.map { p in
                    let f = fills[p] ?? 0
                    return (p, BuddyCluster.State(fill: f, status: f >= 1 ? .done : f > 0 ? .partial : .none, statusLine: ""))
                }),
                onTap: { p in fills[p] = (fills[p] ?? 0) >= 1 ? 0 : 1 },
                onLongPress: { _ in }
            )
        }
    }
    return Demo()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
}
