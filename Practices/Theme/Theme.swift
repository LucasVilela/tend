import SwiftUI
import UIKit

/// An sRGB colour from tokens.json. Views use `Theme` colours, never hex values.
struct RGB: Sendable, Hashable {
    let hex: UInt32
    init(_ hex: UInt32) { self.hex = hex }

    var color: Color {
        Color(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// One text style from the type scale. `tracking` is in em, as in tokens.json.
struct TextStyleToken: Sendable, Hashable {
    let size: CGFloat
    let lineHeight: CGFloat
    let weight: Int
    let tracking: CGFloat

    func with(weight: Int) -> TextStyleToken {
        TextStyleToken(size: size, lineHeight: lineHeight, weight: weight, tracking: tracking)
    }

    func with(size: CGFloat, lineHeight: CGFloat? = nil) -> TextStyleToken {
        TextStyleToken(size: size, lineHeight: lineHeight ?? self.lineHeight, weight: weight, tracking: tracking)
    }
}

/// Semantic colours and type, all generated from design/tokens.json.
enum Theme {
    typealias P = Tokens.Palette

    static let background = P.background.color
    static let hairline = P.hairline.color
    static let track = P.track.color
    static let outline = P.outline.color
    static let outlineStrong = P.outlineStrong.color
    static let surfaceSelected = P.surfaceSelectedAlt.color
    static let tileSurface = P.tileSurface.color
    static let textPrimary = P.textPrimary.color
    static let textSecondary = P.textSecondary.color
    static let textTertiary = P.textTertiary.color
    static let onAccent = P.onAccent.color
    static let mood = P.mood.color
    static let ink = P.moodFaceInk.color
    static let cheek = P.moodCheek.color
    static let sparkleGold = P.sparkleGold.color
    static let sparkleDim = P.sparkleDim.color
    static let wave = Tokens.Shape.waveColor.color
    static let partialOpacity = P.accentPartialOpacity

    static let screenPadding = Tokens.Spacing.screenHorizontal

    enum Font {
        static let displayXL = Tokens.TypeScale.displayXL
        static let display = Tokens.TypeScale.display
        static let statNumber = Tokens.TypeScale.statNumber
        static let title = Tokens.TypeScale.title
        static let entryTitle = Tokens.TypeScale.entryTitle
        static let prompt = Tokens.TypeScale.prompt
        static let rowTitleEmphasis = Tokens.TypeScale.rowTitleEmphasis
        static let body = Tokens.TypeScale.body
        static let bodyLong = Tokens.TypeScale.bodyLong
        static let secondary = Tokens.TypeScale.secondary
        static let caption = Tokens.TypeScale.caption
        static let micro = Tokens.TypeScale.micro
        static let tabLabel = Tokens.TypeScale.tabLabel
    }
}

// MARK: - Fonts

enum ThemeFonts {
    /// PostScript names of the bundled Geist weights.
    static func postScriptName(for weight: Int) -> String {
        switch weight {
        case ..<350: "Geist-Light"
        case ..<450: "Geist-Regular"
        default: "Geist-Medium"
        }
    }

    static let isGeistAvailable: Bool = UIFont(name: "Geist-Regular", size: 12) != nil

    static func systemWeight(_ weight: Int) -> SwiftUI.Font.Weight {
        switch weight {
        case ..<350: .light
        case ..<450: .regular
        case ..<550: .medium
        default: .semibold
        }
    }

    /// The Dynamic Type style a size scales with.
    static func relativeStyle(for size: CGFloat) -> SwiftUI.Font.TextStyle {
        switch size {
        case 40...: .largeTitle
        case 26..<40: .title
        case 20..<26: .title2
        case 17..<20: .title3
        case 16..<17: .body
        case 15..<16: .subheadline
        case 13..<15: .footnote
        case 12..<13: .caption
        default: .caption2
        }
    }

    static func font(_ style: TextStyleToken) -> SwiftUI.Font {
        let relative = relativeStyle(for: style.size)
        if isGeistAvailable {
            return .custom(postScriptName(for: style.weight), size: style.size, relativeTo: relative)
        }
        return .system(size: style.size, weight: systemWeight(style.weight))
    }

    /// Natural line height of the font at this size, used to turn a token line height into line spacing.
    static func naturalLineHeight(_ style: TextStyleToken) -> CGFloat {
        let ui = UIFont(name: postScriptName(for: style.weight), size: style.size)
            ?? .systemFont(ofSize: style.size)
        return ui.lineHeight
    }
}

private struct ThemedTextModifier: ViewModifier {
    let style: TextStyleToken
    let monospacedDigits: Bool

    func body(content: Content) -> some View {
        let font = ThemeFonts.font(style)
        content
            .font(monospacedDigits ? font.monospacedDigit() : font)
            .tracking(style.size * style.tracking)
            .lineSpacing(max(0, style.lineHeight - ThemeFonts.naturalLineHeight(style)))
    }
}

extension View {
    /// Applies a type-scale style (font, tracking, line height). Numbers use tabular digits by default.
    func textStyle(_ style: TextStyleToken, monospacedDigits: Bool = true) -> some View {
        modifier(ThemedTextModifier(style: style, monospacedDigits: monospacedDigits))
    }
}

// MARK: - Practice and mood colours

extension Practice {
    var color: Color {
        switch self {
        case .journal: Tokens.Palette.journal.color
        case .meditation: Tokens.Palette.meditation.color
        case .exercise: Tokens.Palette.exercise.color
        }
    }

    var mutedColor: Color {
        switch self {
        case .journal: Tokens.Palette.journal.color.opacity(Theme.partialOpacity)
        case .meditation: Tokens.Palette.meditationMuted.color
        case .exercise: Tokens.Palette.exerciseMuted.color
        }
    }

    /// Brighter colour used only by the buddies on Today.
    var buddyColor: Color {
        switch self {
        case .journal: Tokens.Palette.buddyJournal.color
        case .meditation: Tokens.Palette.buddyMeditation.color
        case .exercise: Tokens.Palette.buddyExercise.color
        }
    }
}

extension MoodKind {
    var color: Color { (Tokens.moodFaces[assetName] ?? Tokens.Palette.mood).color }
    var faceAsset: String { "mood-\(assetName)" }
    var largeFaceAsset: String { "mood-\(assetName)-large" }
}
