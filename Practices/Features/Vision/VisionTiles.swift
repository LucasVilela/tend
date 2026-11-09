import SwiftUI
import UIKit

/// Sizes and rules for the two-column board. Nothing here tracks progress: tiles are for looking at.
enum VisionLayout {
    static let gap: CGFloat = 10
    static let boardPadding: CGFloat = 20

    /// Image tile heights: small, medium, tall (tall follows the photo between 200 and 250).
    static func imageHeight(heightClass: Int?, aspect: CGFloat?, width: CGFloat) -> CGFloat {
        switch heightClass ?? 1 {
        case 0: return 116
        case 1: return 140
        default: return min(250, max(200, width * (aspect ?? 1.3)))
        }
    }

    /// Picks small, medium or tall from the photo's shape (height ÷ width).
    static func heightClass(forAspect aspect: CGFloat) -> Int {
        aspect < 0.8 ? 0 : aspect < 1.1 ? 1 : 2
    }

    /// Rough tile height, used to put a new tile in the shorter column.
    static func estimatedHeight(_ tile: VisionTile, width: CGFloat = 170) -> CGFloat {
        switch tile.kind {
        case .image:
            let aspect = tile.imageData.flatMap(UIImage.init(data:)).map { $0.size.height / max(1, $0.size.width) }
            return imageHeight(heightClass: tile.heightClass, aspect: aspect, width: width)
        case .text:
            let characters = CGFloat(tile.text?.count ?? 0)
            let lines = max(1, ceil(characters / 14))
            return 36 + 14 + lines * 26 + 10
        }
    }

    /// Goal accents rotate sage, lavender, sand, sky in creation order.
    static func goalAccent(_ index: Int?) -> Color {
        let accents = [Practice.exercise.color, Practice.meditation.color, Practice.journal.color, Theme.mood]
        return accents[(index ?? 0) % accents.count]
    }

    /// Shrinks a photo to at most 1200 px wide and re-encodes it as JPEG for storage.
    static func preparedImageData(_ data: Data) -> (data: Data, heightClass: Int)? {
        guard let image = UIImage(data: data) else { return nil }
        let aspect = image.size.height / max(1, image.size.width)
        let width = min(1200, image.size.width)
        let size = CGSize(width: width, height: width * aspect)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let jpeg = resized.jpegData(compressionQuality: 0.85) else { return nil }
        return (jpeg, heightClass(forAspect: aspect))
    }
}

/// The values a tile shows, so the board and the live preview share one view.
struct TileContent: Equatable {
    var kind: TileKind
    var imageData: Data?
    var heightClass: Int?
    var caption: String?
    var subtitle: String?
    var text: String?
    var label: TextLabel?
    var dueMonth: Date?
    var accentIndex: Int?

    init(_ tile: VisionTile) {
        kind = tile.kind
        imageData = tile.imageData
        heightClass = tile.heightClass
        caption = tile.caption
        subtitle = tile.subtitle
        text = tile.text
        label = tile.textLabel
        dueMonth = tile.dueMonth
        accentIndex = tile.accentIndex
    }

    init(kind: TileKind, imageData: Data? = nil, heightClass: Int? = nil, caption: String? = nil, subtitle: String? = nil,
         text: String? = nil, label: TextLabel? = nil, dueMonth: Date? = nil, accentIndex: Int? = nil) {
        self.kind = kind
        self.imageData = imageData
        self.heightClass = heightClass
        self.caption = caption
        self.subtitle = subtitle
        self.text = text
        self.label = label
        self.dueMonth = dueMonth
        self.accentIndex = accentIndex
    }

    /// "GOAL · MAY", "MANTRA", "WORDS FOR THE YEAR"…
    var labelText: String {
        guard let label else { return "" }
        if label == .goal, let dueMonth { return "GOAL · \(Formats.shortMonth(dueMonth).uppercased())" }
        return label.name.uppercased()
    }

    var accessibilityText: String {
        switch kind {
        case .image: return ["Photo", caption, subtitle].compactMap { $0 }.joined(separator: ", ")
        case .text:
            let due = dueMonth.map { "by \(Formats.monthAndYear($0))" }
            return [label?.name, text, due].compactMap { $0 }.joined(separator: ", ")
        }
    }
}

/// One tile on the board: a photo with an optional caption over a scrim, or a labelled piece of text.
struct VisionTileView: View {
    let content: TileContent
    let width: CGFloat

    var body: some View {
        Group {
            switch content.kind {
            case .image: imageTile
            case .text: textTile
            }
        }
        .frame(width: width)
        .clipShape(OrganicShape.card)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.accessibilityText)
    }

    private var imageTile: some View {
        let image = content.imageData.flatMap(UIImage.init(data:))
        let aspect = image.map { $0.size.height / max(1, $0.size.width) }
        let height = VisionLayout.imageHeight(heightClass: content.heightClass, aspect: aspect, width: width)
        return ZStack(alignment: .bottomLeading) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            } else {
                Theme.tileSurface
            }
            if content.caption?.isEmpty == false || content.subtitle?.isEmpty == false {
                LinearGradient(colors: [Theme.scrim, Theme.scrim.opacity(0)], startPoint: .bottom, endPoint: .top)
                    .frame(height: min(height, 110))
                    .frame(maxHeight: .infinity, alignment: .bottom)
                VStack(alignment: .leading, spacing: 2) {
                    if let caption = content.caption, !caption.isEmpty {
                        Text(caption)
                            .textStyle(Theme.Font.secondary.with(weight: 500), monospacedDigits: false)
                            .foregroundStyle(Theme.onImage)
                    }
                    if let subtitle = content.subtitle, !subtitle.isEmpty {
                        Text(subtitle).textStyle(Theme.Font.micro).foregroundStyle(Theme.onImageSecondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            }
        }
        .frame(width: width, height: height)
    }

    private var textTile: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(content.labelText)
                .textStyle(TextStyleToken(size: 11, lineHeight: 14, weight: 500, tracking: 0.08))
                .foregroundStyle(labelColor)
            Text(displayText)
                .textStyle(textStyle, monospacedDigits: false)
                .foregroundStyle(textColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 18)
        .frame(width: width, alignment: .leading)
        .background(Theme.tileSurface)
    }

    private var displayText: String {
        let text = content.text ?? ""
        return content.label == .quote ? "\u{201C}\(text)\u{201D}" : text
    }

    private var labelColor: Color {
        switch content.label ?? .goal {
        case .goal: VisionLayout.goalAccent(content.accentIndex)
        case .reminder: Theme.mood
        default: Theme.textTertiary
        }
    }

    private var textColor: Color {
        switch content.label ?? .goal {
        case .mantra: Practice.journal.color
        case .quote: Practice.meditation.color
        default: Theme.textPrimary
        }
    }

    private var textStyle: TextStyleToken {
        switch content.label ?? .goal {
        case .mantra: TextStyleToken(size: 22, lineHeight: 28, weight: 300, tracking: -0.01)
        case .wordsForTheYear: TextStyleToken(size: 17, lineHeight: 24, weight: 300, tracking: 0)
        default: TextStyleToken(size: 20, lineHeight: 26, weight: 300, tracking: -0.01)
        }
    }
}
