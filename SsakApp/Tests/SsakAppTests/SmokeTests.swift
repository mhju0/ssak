import XCTest
import SwiftUI
import SsakArt
@testable import SsakApp

final class SmokeTests: XCTestCase {
    @MainActor
    func testPlaceholderRenders() {
        let data = pngData(for: RootPlaceholder(), size: CGSize(width: 120, height: 150))
        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data?.count ?? 0, 100)
    }
}
