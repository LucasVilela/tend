import SwiftUI

/// Eight corner radii in CSS `border-radius` order: horizontal TL, TR, BR, BL, then vertical TL, TR, BR, BL.
/// Animatable, so shapes can morph between two sets of radii.
struct CornerRadii: VectorArithmetic, Sendable, Hashable {
    var values: [Double]

    init(_ v0: Double, _ v1: Double, _ v2: Double, _ v3: Double,
         _ v4: Double, _ v5: Double, _ v6: Double, _ v7: Double) {
        values = [v0, v1, v2, v3, v4, v5, v6, v7]
    }

    private init(values: [Double]) { self.values = values }

    static var zero: CornerRadii { CornerRadii(values: Array(repeating: 0, count: 8)) }

    static func + (lhs: CornerRadii, rhs: CornerRadii) -> CornerRadii {
        CornerRadii(values: zip(lhs.values, rhs.values).map { $0 + $1 })
    }

    static func - (lhs: CornerRadii, rhs: CornerRadii) -> CornerRadii {
        CornerRadii(values: zip(lhs.values, rhs.values).map { $0 - $1 })
    }

    mutating func scale(by rhs: Double) { values = values.map { $0 * rhs } }

    var magnitudeSquared: Double { values.reduce(0) { $0 + $1 * $1 } }

    /// Linear blend between two sets of radii.
    static func mix(_ a: CornerRadii, _ b: CornerRadii, _ t: Double) -> CornerRadii {
        CornerRadii(values: zip(a.values, b.values).map { $0 + ($1 - $0) * t })
    }
}

/// A rectangle with independent elliptical corners, like CSS `border-radius: a b c d / e f g h`.
/// Radii are fractions of the size (`.relative`) or points (`.absolute`); oversized radii are scaled
/// down the way browsers do, so `.absolute` radii on a short pill still give a pill.
struct OrganicShape: InsettableShape {
    enum Unit: Hashable { case relative, absolute }

    var radii: CornerRadii
    var unit: Unit
    var insetAmount: CGFloat = 0

    var animatableData: CornerRadii {
        get { radii }
        set { radii = newValue }
    }

    func inset(by amount: CGFloat) -> OrganicShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }

    func path(in fullRect: CGRect) -> Path {
        let rect = fullRect.insetBy(dx: insetAmount, dy: insetAmount)
        guard rect.width > 0, rect.height > 0 else { return Path() }
        let v = radii.values
        let w = rect.width, h = rect.height
        var hx = [v[0], v[1], v[2], v[3]].map { CGFloat($0) }
        var vy = [v[4], v[5], v[6], v[7]].map { CGFloat($0) }
        if unit == .relative {
            hx = hx.map { $0 * w }
            vy = vy.map { $0 * h }
        }
        // CSS rule: scale every radius down if any side's radii overlap.
        let factors = [w / (hx[0] + hx[1]), h / (vy[1] + vy[2]), w / (hx[2] + hx[3]), h / (vy[3] + vy[0])]
        let f = min(1, factors.filter { $0.isFinite }.min() ?? 1)
        hx = hx.map { $0 * f }
        vy = vy.map { $0 * f }

        let (minX, minY, maxX, maxY) = (rect.minX, rect.minY, rect.maxX, rect.maxY)
        var p = Path()
        p.move(to: CGPoint(x: minX + hx[0], y: minY))
        p.addLine(to: CGPoint(x: maxX - hx[1], y: minY))
        p.addCorner(from: CGPoint(x: maxX - hx[1], y: minY), corner: CGPoint(x: maxX, y: minY), to: CGPoint(x: maxX, y: minY + vy[1]))
        p.addLine(to: CGPoint(x: maxX, y: maxY - vy[2]))
        p.addCorner(from: CGPoint(x: maxX, y: maxY - vy[2]), corner: CGPoint(x: maxX, y: maxY), to: CGPoint(x: maxX - hx[2], y: maxY))
        p.addLine(to: CGPoint(x: minX + hx[3], y: maxY))
        p.addCorner(from: CGPoint(x: minX + hx[3], y: maxY), corner: CGPoint(x: minX, y: maxY), to: CGPoint(x: minX, y: maxY - vy[3]))
        p.addLine(to: CGPoint(x: minX, y: minY + vy[0]))
        p.addCorner(from: CGPoint(x: minX, y: minY + vy[0]), corner: CGPoint(x: minX, y: minY), to: CGPoint(x: minX + hx[0], y: minY))
        p.closeSubpath()
        return p
    }
}

private extension Path {
    /// Quarter ellipse from `from` to `to`, bulging towards `corner`.
    mutating func addCorner(from: CGPoint, corner: CGPoint, to: CGPoint) {
        let k: CGFloat = 0.5523
        addCurve(
            to: to,
            control1: CGPoint(x: from.x + (corner.x - from.x) * k, y: from.y + (corner.y - from.y) * k),
            control2: CGPoint(x: to.x + (corner.x - to.x) * k, y: to.y + (corner.y - to.y) * k)
        )
    }
}

extension OrganicShape {
    /// Organic stand-in for a circle (dots, day markers, faces, round buttons).
    static var blob: OrganicShape { OrganicShape(radii: Tokens.Shape.blobRadius, unit: .relative) }
    static func blob(_ radii: CornerRadii) -> OrganicShape { OrganicShape(radii: radii, unit: .relative) }
    /// Organic stand-in for a capsule (pills, chips, switches, primary buttons).
    static var capsule: OrganicShape { OrganicShape(radii: Tokens.Shape.capsuleRadius, unit: .absolute) }
    /// Organic card corners (vision tiles).
    static var card: OrganicShape { OrganicShape(radii: Tokens.Shape.cardRadius, unit: .absolute) }
}

/// The gentle sine line used instead of hairlines (period 48 pt, amplitude 1.2 pt).
struct WaveLine: Shape {
    var phase: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let period = Tokens.Shape.waveHalfPeriod * 2
        let amplitude = Tokens.Shape.waveAmplitude
        var p = Path()
        let midY = rect.midY
        var x = rect.minX
        p.move(to: CGPoint(x: x, y: midY - amplitude * sin((x + phase) / period * 2 * .pi)))
        while x < rect.maxX {
            x = min(rect.maxX, x + 2)
            p.addLine(to: CGPoint(x: x, y: midY - amplitude * sin((x + phase) / period * 2 * .pi)))
        }
        return p
    }
}

/// A wavy separator, 6 pt tall, matching design/images/wave.svg.
struct WaveDivider: View {
    var color: Color = Theme.wave

    var body: some View {
        WaveLine()
            .stroke(color, style: StrokeStyle(lineWidth: Tokens.Shape.waveStroke, lineCap: .round))
            .frame(height: 6)
            .accessibilityHidden(true)
    }
}
