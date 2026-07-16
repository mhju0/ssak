// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MeokKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SkyState", targets: ["SkyState"])
    ],
    targets: [
        .target(name: "SkyState"),
        .testTarget(
            name: "SkyStateTests",
            dependencies: ["SkyState"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
