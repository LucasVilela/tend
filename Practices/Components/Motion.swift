import SwiftUI

/// Time-based helpers for the looping, hand-made motion (wobble, bob, blink…).
/// Views drive them from a `TimelineView`, which is paused when Reduce Motion is on.
enum Loop {
    /// Progress 0..<1 through a loop of `period` seconds. A negative `delay` starts part-way in, like CSS.
    static func progress(_ time: TimeInterval, period: Double, delay: Double = 0) -> Double {
        let t = (time - delay) / period
        return t - floor(t)
    }

    /// CSS-like ease-in-out.
    static func ease(_ t: Double) -> Double { t * t * (3 - 2 * t) }

    /// Morph through `keyframes` (evenly spaced, returning to the first) with ease-in-out between them.
    static func radii(_ keyframes: [CornerRadii], time: TimeInterval, period: Double, delay: Double = 0) -> CornerRadii {
        guard keyframes.count > 1 else { return keyframes.first ?? Tokens.Shape.blobRadius }
        let p = progress(time, period: period, delay: delay) * Double(keyframes.count)
        let index = Int(p) % keyframes.count
        let next = (index + 1) % keyframes.count
        return CornerRadii.mix(keyframes[index], keyframes[next], ease(p - floor(p)))
    }

    /// Up-and-down offset: 0 → -amplitude → 0 over the period, eased.
    static func bob(_ time: TimeInterval, period: Double, delay: Double, amplitude: CGFloat) -> CGFloat {
        let p = progress(time, period: period, delay: delay)
        return -amplitude * CGFloat(0.5 - 0.5 * cos(p * 2 * .pi))
    }
}

/// Drives a view from the animation clock, paused (time frozen at 0) when Reduce Motion is on.
struct MotionClock<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ViewBuilder var content: (TimeInterval) -> Content

    var body: some View {
        if reduceMotion {
            content(0)
        } else {
            TimelineView(.animation) { context in
                content(context.date.timeIntervalSinceReferenceDate)
            }
        }
    }
}

extension View {
    /// The 0.7 s squash-and-stretch bounce, played whenever `trigger` changes.
    func squashBounce<T: Equatable>(trigger: T) -> some View {
        keyframeAnimator(initialValue: CGSize(width: 1, height: 1), trigger: trigger) { content, scale in
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
    }
}

/// A blob that slowly morphs between the two `blobmorph` shapes (9 s loop). Static with Reduce Motion.
struct WobblingBlob<Content: View>: View {
    var delay: Double = 0
    @ViewBuilder var content: (OrganicShape) -> Content

    var body: some View {
        MotionClock { time in
            content(.blob(Loop.radii(Tokens.Shape.blobMorph, time: time, period: Tokens.Shape.blobMorphSeconds, delay: delay)))
        }
    }
}
