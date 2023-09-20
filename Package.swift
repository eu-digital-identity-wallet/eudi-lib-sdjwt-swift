// swift-tools-version: 5.7.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "eudi-lib-sdjwt-swift",
    platforms: [
        .iOS(.v14),
        .tvOS(.v12),
        .watchOS(.v5),
        .macOS(.v12)

    ],
    products: [
        .library(
            name: "eudi-lib-sdjwt-swift",
            targets: ["eudi-lib-sdjwt-swift"])
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.1"),
        .package(url: "https://github.com/airsidemobile/JOSESwift.git", from: "2.3.0")
    ],
    targets: [
        .target(
            name: "eudi-lib-sdjwt-swift",
            dependencies: [
                .product(name: "SwiftyJSON", package: "swiftyjson"),
                .product(name: "JOSESwift", package: "JOSESwift")
            ],
            path: "Sources",
            plugins: [
            ]
        ),
        .testTarget(
            name: "eudi-lib-sdjwt-swiftTests",
            dependencies: ["eudi-lib-sdjwt-swift"],
            path: "Tests")

    ]
)
