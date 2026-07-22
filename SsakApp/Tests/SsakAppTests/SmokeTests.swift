import XCTest
import SwiftUI
import SsakArt
@testable import SsakApp

final class SmokeTests: XCTestCase {
    /// The render loop works: a real SsakApp screen renders to a non-empty PNG.
    @MainActor
    func testAppViewRenders() {
        let data = pngData(for: StartGuide(anchors: [:], speciesName: "Marigold", onDone: {}),
                           size: CGSize(width: 120, height: 150))
        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data?.count ?? 0, 100)
    }
}
