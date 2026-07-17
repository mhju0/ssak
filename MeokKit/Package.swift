// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MeokKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SkyState", targets: ["SkyState"]),
        .library(name: "StrokeEngine", targets: ["StrokeEngine"]),
        .library(name: "GameKernel", targets: ["GameKernel"]),
    ],
    targets: [
        .target(name: "SkyState"),
        .testTarget(
            name: "SkyStateTests",
            dependencies: ["SkyState"],
            resources: [.copy("Fixtures")]
        ),
        .target(name: "StrokeEngine"),
        .testTarget(name: "StrokeEngineTests", dependencies: ["StrokeEngine"]),
        .target(name: "GameKernel"),
        .testTarget(name: "GameKernelTests", dependencies: ["GameKernel"]),
    ]
)
