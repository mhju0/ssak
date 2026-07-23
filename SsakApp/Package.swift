// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SsakApp",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "SsakApp", targets: ["SsakApp"]),
    ],
    dependencies: [
        .package(path: "../SsakCore"),
        .package(path: "../SsakArt"),
    ],
    targets: [
        .target(name: "SsakApp", dependencies: [
            .product(name: "SsakCore", package: "SsakCore"),
            .product(name: "SsakArt", package: "SsakArt"),
        ], resources: [.copy("Resources/Fonts")]),
        .executableTarget(name: "SsakAppRender", dependencies: [
            "SsakApp",
            .product(name: "SsakArt", package: "SsakArt"),
            .product(name: "SsakCore", package: "SsakCore"),
        ]),
        .testTarget(name: "SsakAppTests", dependencies: [
            "SsakApp",
            .product(name: "SsakCore", package: "SsakCore"),
            .product(name: "SsakArt", package: "SsakArt"),
        ]),
    ]
)
