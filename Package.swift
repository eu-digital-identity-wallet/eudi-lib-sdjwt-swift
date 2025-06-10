// swift-tools-version: 6.0.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "eudi-lib-sdjwt-swift",
  platforms: [
    .iOS(.v14),
    .tvOS(.v14),
    .watchOS(.v5),
    .macOS(.v14)
    
  ],
  products: [
    .library(
      name: "eudi-lib-sdjwt-swift",
      targets: ["eudi-lib-sdjwt-swift"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/SwiftyJSON/SwiftyJSON.git",
      from: "5.0.1"
    ),
    .package(
      url: "https://github.com/beatt83/jose-swift.git",
      from: "4.0.0"
    ),
    .package(
      url: "https://github.com/apple/swift-certificates.git",
      from: "1.0.0"
    ),
    .package(
      url: "https://github.com/niscy-eudiw/BlueECC.git",
      .upToNextMajor(from: "1.2.4")
    ),
    .package(
      url: "https://github.com/krzyzanowskim/CryptoSwift.git",
      from: "1.8.4"
    ),
    .package(
      url: "https://github.com/ajevans99/swift-json-schema",
      from: "0.7.0"
    )
  ],
  targets: [
    .target(
      name: "eudi-lib-sdjwt-swift",
      dependencies: [
        "jose-swift",
        "CryptoSwift",
        .product(name: "SwiftyJSON", package: "swiftyjson"),
        .product(name: "X509", package: "swift-certificates"),
        .product(name: "JSONSchema", package: "swift-json-schema"),
        .product(name: "JSONSchemaBuilder", package: "swift-json-schema"),
        .product(
          name: "CryptorECC",
          package: "BlueECC"
        ),
      ],
      path: "Sources",
      plugins: [
      ]
    ),
    .testTarget(
      name: "eudi-lib-sdjwt-swiftTests",
      dependencies: ["eudi-lib-sdjwt-swift"],
      path: "Tests",
      resources: [
        .process("Resources")
      ]
    )
  ]
)
