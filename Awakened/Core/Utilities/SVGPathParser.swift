import SwiftUI
import CoreGraphics

/// Tiny SVG-path parser for `d` attribute strings.
/// Supports the subset of commands used by our anatomy mockups:
///   M / m  — moveTo (absolute / relative)
///   L / l  — lineTo
///   H / h  — horizontal line
///   V / v  — vertical line
///   C / c  — cubic Bezier
///   Z / z  — close
///
/// Designed to be small + correct for our paths, not a full SVG implementation.
enum SVGPathParser {
    
    /// Parse an SVG `d` attribute string into a SwiftUI `Path`.
    /// The path is rendered in SVG coordinate space; callers should apply
    /// a `.transform`, `GeometryReader` scale, or `aspectRatio` as needed.
    static func parse(_ d: String) -> Path {
        var path = Path()
        let scanner = PathScanner(d)
        var current = CGPoint.zero
        var start = CGPoint.zero
        var lastControl: CGPoint? = nil
        
        while let command = scanner.nextCommand() {
            switch command {
            case "M", "m":
                let pts = scanner.readPoints(count: 1, relative: command == "m", origin: current)
                guard let p = pts.first else { continue }
                path.move(to: p)
                current = p
                start = p
                // Subsequent implicit pairs after M are L/l
                while let extra = scanner.peekNumber() {
                    _ = extra
                    let more = scanner.readPoints(count: 1, relative: command == "m", origin: current)
                    guard let mp = more.first else { break }
                    path.addLine(to: mp)
                    current = mp
                }
                lastControl = nil
                
            case "L", "l":
                while scanner.peekNumber() != nil {
                    let pts = scanner.readPoints(count: 1, relative: command == "l", origin: current)
                    guard let p = pts.first else { break }
                    path.addLine(to: p)
                    current = p
                }
                lastControl = nil
                
            case "H", "h":
                while let x = scanner.readNumber() {
                    let nx = command == "h" ? current.x + x : x
                    let p = CGPoint(x: nx, y: current.y)
                    path.addLine(to: p)
                    current = p
                }
                lastControl = nil
                
            case "V", "v":
                while let y = scanner.readNumber() {
                    let ny = command == "v" ? current.y + y : y
                    let p = CGPoint(x: current.x, y: ny)
                    path.addLine(to: p)
                    current = p
                }
                lastControl = nil
                
            case "C", "c":
                while scanner.peekNumber() != nil {
                    let pts = scanner.readPoints(count: 3, relative: command == "c", origin: current)
                    guard pts.count == 3 else { break }
                    path.addCurve(to: pts[2], control1: pts[0], control2: pts[1])
                    current = pts[2]
                    lastControl = pts[1]
                }
                
            case "Z", "z":
                path.closeSubpath()
                current = start
                lastControl = nil
                
            default:
                // Skip unknown command's parameters
                while scanner.readNumber() != nil { }
            }
        }
        
        return path
    }
}

// MARK: - Path Scanner

/// Hand-rolled scanner that walks an SVG path-data string command by command.
/// Whitespace and commas are treated as separators between numbers.
private final class PathScanner {
    private let chars: [Character]
    private var i: Int = 0
    
    init(_ s: String) {
        self.chars = Array(s)
    }
    
    /// Returns the next single-character command (M, L, C, Z, etc.) or nil at EOF.
    func nextCommand() -> Character? {
        skipSeparators()
        guard i < chars.count else { return nil }
        let c = chars[i]
        if c.isLetter {
            i += 1
            return c
        }
        return nil
    }
    
    /// Peek at the next non-separator character to see if it's a number (digit, sign, or dot).
    func peekNumber() -> Bool? {
        skipSeparators()
        guard i < chars.count else { return nil }
        let c = chars[i]
        if c.isNumber || c == "-" || c == "+" || c == "." { return true }
        return nil
    }
    
    /// Read the next floating-point number (consuming it).
    func readNumber() -> CGFloat? {
        skipSeparators()
        guard i < chars.count else { return nil }
        var s = ""
        if chars[i] == "-" || chars[i] == "+" {
            s.append(chars[i]); i += 1
        }
        var hasDigit = false
        var hasDot = false
        while i < chars.count {
            let c = chars[i]
            if c.isNumber { s.append(c); i += 1; hasDigit = true }
            else if c == "." && !hasDot { s.append(c); i += 1; hasDot = true }
            else if (c == "e" || c == "E") {
                s.append(c); i += 1
                if i < chars.count, chars[i] == "-" || chars[i] == "+" { s.append(chars[i]); i += 1 }
            }
            else { break }
        }
        guard hasDigit else { return nil }
        return CGFloat(Double(s) ?? 0)
    }
    
    /// Read `count` points (`count × 2` numbers). For relative commands, each point is
    /// offset from the supplied `origin`; subsequent points in a multi-point read
    /// stay relative to that same origin (callers re-set origin between iterations).
    func readPoints(count: Int, relative: Bool, origin: CGPoint) -> [CGPoint] {
        var pts: [CGPoint] = []
        for _ in 0..<count {
            guard let x = readNumber(), let y = readNumber() else { break }
            let p = relative ? CGPoint(x: origin.x + x, y: origin.y + y) : CGPoint(x: x, y: y)
            pts.append(p)
        }
        return pts
    }
    
    private func skipSeparators() {
        while i < chars.count {
            let c = chars[i]
            if c.isWhitespace || c == "," { i += 1 } else { break }
        }
    }
}
