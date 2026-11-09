import SwiftUI

/// Builds a `Path` from SVG path data (M, L, H, V, Q, T, C, S, Z; absolute and relative; no arcs).
/// Used for the small hand-drawn marks from the design files (check faces, icons, the star).
enum SVGPath {
    static func path(_ data: String) -> Path {
        var path = Path()
        var tokens = tokenize(data)[...]
        var current = CGPoint.zero
        var start = CGPoint.zero
        var lastControl: CGPoint?
        var command: Character = "M"

        func number() -> CGFloat {
            guard case .number(let n)? = tokens.first else { return 0 }
            tokens.removeFirst()
            return n
        }
        func point(relative: Bool) -> CGPoint {
            let x = number(), y = number()
            return relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
        }

        while let token = tokens.first {
            if case .command(let c) = token {
                command = c
                tokens.removeFirst()
            }
            let relative = command.isLowercase
            switch command.uppercased().first! {
            case "M":
                current = point(relative: relative)
                start = current
                path.move(to: current)
                command = relative ? "l" : "L"
                lastControl = nil
            case "L":
                current = point(relative: relative)
                path.addLine(to: current)
                lastControl = nil
            case "H":
                let x = number()
                current.x = relative ? current.x + x : x
                path.addLine(to: current)
                lastControl = nil
            case "V":
                let y = number()
                current.y = relative ? current.y + y : y
                path.addLine(to: current)
                lastControl = nil
            case "Q":
                let control = point(relative: relative)
                let end = point(relative: relative)
                path.addQuadCurve(to: end, control: control)
                lastControl = control
                current = end
            case "T":
                let control = lastControl.map { CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y) } ?? current
                let end = point(relative: relative)
                path.addQuadCurve(to: end, control: control)
                lastControl = control
                current = end
            case "C":
                let c1 = point(relative: relative)
                let c2 = point(relative: relative)
                let end = point(relative: relative)
                path.addCurve(to: end, control1: c1, control2: c2)
                lastControl = c2
                current = end
            case "S":
                let c1 = lastControl.map { CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y) } ?? current
                let c2 = point(relative: relative)
                let end = point(relative: relative)
                path.addCurve(to: end, control1: c1, control2: c2)
                lastControl = c2
                current = end
            case "Z":
                path.closeSubpath()
                current = start
                lastControl = nil
                if case .number? = tokens.first { tokens.removeFirst() }
            default:
                tokens.removeFirst()
            }
        }
        return path
    }

    private enum Token { case command(Character), number(CGFloat) }

    private static func tokenize(_ data: String) -> [Token] {
        var result: [Token] = []
        var buffer = ""
        func flush() {
            if let value = Double(buffer) { result.append(.number(CGFloat(value))) }
            buffer = ""
        }
        for ch in data {
            if ch.isLetter && ch != "e" {
                flush()
                result.append(.command(ch))
            } else if ch == "-" && !buffer.isEmpty && buffer.last != "e" {
                flush()
                buffer.append(ch)
            } else if ch == "." && buffer.contains(".") {
                flush()
                buffer.append(ch)
            } else if ch == " " || ch == "," || ch == "\n" {
                flush()
            } else {
                buffer.append(ch)
            }
        }
        flush()
        return result
    }
}

/// A shape drawn from SVG path data in a square `viewBox` of the given size, scaled to fit its frame.
struct SVGShape: Shape {
    let data: String
    var viewBox: CGFloat = 24

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / viewBox
        return SVGPath.path(data)
            .applying(CGAffineTransform(scaleX: scale, y: scale))
            .offsetBy(dx: rect.minX, dy: rect.minY)
    }
}
