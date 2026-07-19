import XCTest
import SwiftUI
import ImageIO
import SsakCore
@testable import SsakArt

final class RenderInvariantsTests: XCTestCase {
    @MainActor
    func testRendersNonEmptyPNGOfExpectedSize() {
        let view = ZStack { Color.orange; Circle().fill(.white).frame(width: 40, height: 40) }
        let data = pngData(for: view, size: CGSize(width: 100, height: 120), scale: 2)
        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data?.count ?? 0, 100)          // real image, not empty
        XCTAssertEqual(pngPixelSize(data!), CGSize(width: 200, height: 240))  // size * scale
    }

    func testPaletteExistsForEveryCatalogSpecies() {
        for s in SpeciesCatalog.all {
            // must not trap / must return a distinct-ish bloom color per species
            _ = SpeciesPalette.palette(for: s.id)
        }
        XCTAssertNotEqual(SpeciesPalette.palette(for: "marigold").bloom,
                          SpeciesPalette.palette(for: "cosmos").bloom)
    }

    @MainActor
    func testDroopAltersRenderedImage() {
        let base = ZStack { Color.green; Circle().fill(.orange).frame(width: 30, height: 30) }
        let a = pngData(for: base.droop(0), size: CGSize(width: 80, height: 80))
        let b = pngData(for: base.droop(0.9), size: CGSize(width: 80, height: 80))
        XCTAssertNotNil(a); XCTAssertNotNil(b)
        XCTAssertNotEqual(a, b)   // the effect must visibly change the image
    }

    @MainActor
    func testMarigoldStagesRenderDistinctly() {
        let m = SpeciesCatalog.marigold
        let size = CGSize(width: 180, height: 220)
        var seen: [Data] = []
        for stage in GrowthStage.allCases {
            let data = pngData(for: PlantView(species: m, stage: stage, droop: 0), size: size)
            XCTAssertNotNil(data, "\(stage) failed to render")
            for prior in seen { XCTAssertNotEqual(prior, data, "\(stage) is identical to an earlier stage") }
            seen.append(data!)
        }
    }
}

/// Read width/height back out of PNG bytes to confirm the render honoured size*scale.
func pngPixelSize(_ data: Data) -> CGSize {
    guard let src = CGImageSourceCreateWithData(data as CFData, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return .zero }
    return CGSize(width: img.width, height: img.height)
}
