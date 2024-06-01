// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-tca-extras",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(name: "TCAExtras", targets: ["TCAExtras"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      from: "1.0.0"
    ),
    .package(
      url: "https://github.com/apple/swift-docc-plugin.git",
      from: "1.0.0"
    ),
  ],
  targets: [
    .target(
      name: "TCAExtras",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .testTarget(
      name: "TCAExtrasTests",
      dependencies: ["TCAExtras"]
    ),
  ]
)
