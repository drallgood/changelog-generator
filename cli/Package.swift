// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Changelog Generator",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .executable(name: "changelog-generator", targets: ["changelog-generator"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "changelog-generator",
            dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser")]),
        .testTarget(
            name: "changelog-generatorTests",
            dependencies: ["changelog-generator"],
            exclude:["test.json"]
        ),
    ]
)
