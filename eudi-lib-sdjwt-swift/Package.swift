// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "eudi-lib-sdjwt-swift",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "eudi-lib-sdjwt-swift",
            targets: ["eudi-lib-sdjwt-swift"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),

        .package(url: "https://github.com/yonaskolb/Codability", .upToNextMajor(from: "0.2.1"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "eudi-lib-sdjwt-swift",
            dependencies: [
                .product(name: "Codability", package: "Codability"),
            ]),
        .testTarget(
            name: "eudi-lib-sdjwt-swiftTests",
            dependencies: ["eudi-lib-sdjwt-swift"]),
    ]
)
