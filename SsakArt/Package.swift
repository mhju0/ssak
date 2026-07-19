// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SsakArt",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "SsakArt", targets: ["SsakArt"]),
    ],
    dependencies: [
        .package(path: "../SsakCore"),
    ],
    targets: [
        .target(name: "SsakArt", dependencies: [.product(name: "SsakCore", package: "SsakCore")]),
        .executableTarget(name: "SsakArtRender", dependencies: ["SsakArt",
            .product(name: "SsakCore", package: "SsakCore")]),
        .testTarget(name: "SsakArtTests", dependencies: ["SsakArt",
            .product(name: "SsakCore", package: "SsakCore")]),
    ]
)
