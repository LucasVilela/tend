import SwiftUI

/// Line icons from the design files, drawn in a 24 × 24 box.
enum Icon {
    case today, journal, meditate, exercise, vision, chart, plus, minus, chevronLeft, chevronRight, close, check

    init(_ tab: AppTab) {
        switch tab {
        case .today: self = .today
        case .journal: self = .journal
        case .meditate: self = .meditate
        case .exercise: self = .exercise
        case .vision: self = .vision
        }
    }

    var path: Path {
        var p = Path()
        switch self {
        case .today:
            for (x, y) in [(9.0, 9.0), (15, 9), (12, 14.5)] {
                p.addEllipse(in: CGRect(x: x - 5.2, y: y - 5.2, width: 10.4, height: 10.4))
            }
        case .journal:
            // The design's pencil; its two small arcs are drawn as quadratic curves.
            p.addPath(SVGPath.path("M4 20V16.5L15.5 5Q17 3.74 18.5 5L19 5.5Q20.26 7 19 8.5L7.5 20H4Z M13.5 7l3.5 3.5"))
        case .meditate:
            p.addEllipse(in: CGRect(x: 4, y: 4, width: 16, height: 16))
            p.addEllipse(in: CGRect(x: 8.5, y: 8.5, width: 7, height: 7))
        case .exercise:
            p.addPath(SVGPath.path("M3 12h4l2.5-6 5 12 2.5-6h4"))
        case .vision:
            for r in [CGRect(x: 4, y: 4, width: 7, height: 9), CGRect(x: 13, y: 4, width: 7, height: 5),
                      CGRect(x: 13, y: 11, width: 7, height: 9), CGRect(x: 4, y: 15, width: 7, height: 5)] {
                p.addRoundedRect(in: r, cornerSize: CGSize(width: 1.5, height: 1.5))
            }
        case .chart:
            p.addPath(SVGPath.path("M6 19V13M12 19V6M18 19v-9"))
        case .plus:
            p.addPath(SVGPath.path("M12 6v12M6 12h12"))
        case .minus:
            p.addPath(SVGPath.path("M6 12h12"))
        case .chevronLeft:
            p.addPath(SVGPath.path("M15 6l-6 6 6 6"))
        case .chevronRight:
            p.addPath(SVGPath.path("M9 6l6 6-6 6"))
        case .close:
            p.addPath(SVGPath.path("M6 6l12 12M18 6L6 18"))
        case .check:
            p.addPath(SVGPath.path("M5 12.5l4.5 4.5L19 7.5"))
        }
        return p
    }
}

/// An `Icon` stroked in the current foreground style.
struct IconView: View {
    let icon: Icon
    var size: CGFloat = 22
    var lineWidth: CGFloat = 1.4

    var body: some View {
        IconShape(icon: icon)
            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Scales the 24 pt icon art to its frame (the stroke width stays in points).
private struct IconShape: Shape {
    let icon: Icon
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        return icon.path
            .applying(CGAffineTransform(scaleX: s, y: s))
            .offsetBy(dx: rect.minX, dy: rect.minY)
    }
}
