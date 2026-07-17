// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MeokKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SkyState", targets: ["SkyState"]),
        .library(name: "StrokeEngine", targets: ["StrokeEngine"]),
        .library(name: "GameKernel", targets: ["GameKernel"]),
        .library(name: "Persistence", targets: ["Persistence"]),
    ],
    targets: [
        .target(name: "SkyState", dependencies: ["GameKernel"]),
        .testTarget(
            name: "SkyStateTests",
            dependencies: ["SkyState", "GameKernel"],
            resources: [.copy("Fixtures")]
        ),
        .target(name: "StrokeEngine"),
        .testTarget(name: "StrokeEngineTests", dependencies: ["StrokeEngine", "GameKernel"]),
        .target(name: "GameKernel"),
        .testTarget(name: "GameKernelTests", dependencies: ["GameKernel"]),
        .target(name: "Persistence", dependencies: ["GameKernel"]),
        .testTarget(name: "PersistenceTests", dependencies: ["Persistence"]),
    ]
)
