// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MobileWhepClient",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MobileWhepClient",
            targets: ["MobileWhepClient"])
    ],
    dependencies: [
        .package(name: "WebRTC", url: "https://github.com/webrtc-sdk/Specs.git", .exact("125.6422.03")),
        .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.4.2")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MobileWhepClient",
            dependencies: [
                "WebRTC",
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .testTarget(
            name: "MobileWhepClientTests",
            dependencies: ["MobileWhepClient"]),
    ]
)
