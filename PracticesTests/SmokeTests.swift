import SwiftData
import XCTest
@testable import Practices

@MainActor
final class SmokeTests: XCTestCase {
    func testSeedsBuiltInTemplatesOnce() throws {
        let container = try AppSchema.makeContainer(inMemory: true)
        let context = container.mainContext
        XCTAssertEqual(try TemplateSeeder.seedIfNeeded(context), 4)
        XCTAssertEqual(try TemplateSeeder.seedIfNeeded(context), 0)
        let templates = try context.fetch(FetchDescriptor<GuidedTemplate>(sortBy: [SortDescriptor(\.sortOrder)]))
        XCTAssertEqual(templates.map(\.name), ["Morning intention", "Evening reflection", "Gratitude", "Weekly review"])
        XCTAssertEqual(templates.map(\.questions.count), [3, 4, 3, 5])
    }

    func testEveryMoodHasFaceArtAndColour() {
        for mood in MoodKind.allCases {
            XCTAssertNotNil(UIImage(named: mood.faceAsset), mood.faceAsset)
            XCTAssertNotNil(UIImage(named: mood.largeFaceAsset), mood.largeFaceAsset)
            XCTAssertNotNil(Tokens.moodFaces[mood.assetName], mood.assetName)
        }
    }

    func testGeistIsBundled() {
        for name in ["Geist-Light", "Geist-Regular", "Geist-Medium"] {
            XCTAssertNotNil(UIFont(name: name, size: 12), name)
        }
    }

    func testMoodLogKeepsAtMostThreeMoods() {
        let log = MoodLog(loggedAt: .now, moods: [.happy, .calm, .excited, .sad])
        XCTAssertEqual(log.moods, [.happy, .calm, .excited])
    }
}
