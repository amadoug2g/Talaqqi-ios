// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ShadowingCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "ShadowingCore", targets: ["ShadowingCore"]),
    ],
    targets: [
        .target(name: "ShadowingCore"),
        .testTarget(name: "ShadowingCoreTests", dependencies: ["ShadowingCore"]),
    ]
)
