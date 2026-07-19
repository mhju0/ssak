// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SsakCore",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [.library(name: "SsakCore", targets: ["SsakCore"])],
    targets: [
        .target(name: "SsakCore"),
        .testTarget(name: "SsakCoreTests", dependencies: ["SsakCore"]),
    ]
)
