import XCTest
@testable import GameKernel

final class ScrollGeometryTests: XCTestCase {
    // Worked example: 800pt screen, five zones → 4000pt world.
    private let screen = 800.0
    private let world = 4000.0

    // MARK: Camera clamping

    func testCameraClampsAtBothEdges() {
        // Camera center can't go below half a screen or above world minus half.
        XCTAssertEqual(ScrollGeometry.clampedCameraY(0, screenHeight: screen, worldHeight: world), 400)
        XCTAssertEqual(ScrollGeometry.clampedCameraY(9999, screenHeight: screen, worldHeight: world), 3600)
        XCTAssertEqual(ScrollGeometry.clampedCameraY(2000, screenHeight: screen, worldHeight: world), 2000)
    }

    func testDegenerateWorldPinsToCenter() {
        // World no taller than a screen → camera pinned at world center.
        XCTAssertEqual(ScrollGeometry.clampedCameraY(123, screenHeight: 800, worldHeight: 600), 300)
    }

    // MARK: Flick deceleration target

    func testFlickCarriesProportionalToVelocityAndClamps() {
        let base = 2000.0
        // Zero velocity goes nowhere.
        XCTAssertEqual(
            ScrollGeometry.flickTarget(from: base, velocity: 0, screenHeight: screen, worldHeight: world),
            base)
        // A downward-scroll flick moves up the value in its direction…
        let carried = ScrollGeometry.flickTarget(from: base, velocity: 1000, screenHeight: screen, worldHeight: world)
        XCTAssertGreaterThan(carried, base)
        // …symmetrically…
        let carriedDown = ScrollGeometry.flickTarget(from: base, velocity: -1000, screenHeight: screen, worldHeight: world)
        XCTAssertEqual(base - carriedDown, carried - base, accuracy: 0.001)
        // …and a huge flick still lands inside the clamped range.
        let flung = ScrollGeometry.flickTarget(from: base, velocity: 1_000_000, screenHeight: screen, worldHeight: world)
        XCTAssertEqual(flung, 3600)
    }

    // MARK: Zones by altitude

    func testZoneOrderClimbsFromPondToPeak() {
        // Spec §3: valley pond at the bottom, peak at the top.
        XCTAssertEqual(Zone.allCases.first, .valleyPond)
        XCTAssertEqual(Zone.allCases.last, .peak)
        XCTAssertEqual(Zone.allCases.count, 5)
    }

    func testZoneAtCameraAltitude() {
        XCTAssertEqual(Zone.at(cameraY: 400, screenHeight: screen), .valleyPond)
        XCTAssertEqual(Zone.at(cameraY: 1200, screenHeight: screen), .gardenTerrace)
        XCTAssertEqual(Zone.at(cameraY: 2000, screenHeight: screen), .hermitage)
        XCTAssertEqual(Zone.at(cameraY: 2800, screenHeight: screen), .forest)
        XCTAssertEqual(Zone.at(cameraY: 3600, screenHeight: screen), .peak)
        // Outside the world still resolves to the nearest zone.
        XCTAssertEqual(Zone.at(cameraY: -50, screenHeight: screen), .valleyPond)
        XCTAssertEqual(Zone.at(cameraY: 99999, screenHeight: screen), .peak)
    }
}
