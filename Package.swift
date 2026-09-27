// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OptikosPrimeSDK",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "OptikosPrimeSDK",
            targets: ["OptikosPrimeSDK"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jurajantas/MediapipeSwiftPackage", from: "1.0.0")
    ],
    targets: [
        .binaryTarget(
            name: "OptikosPrimeSDK",
            url: "url-to-zip.zip",
            checksum: "f85e8491dd14d89fa0f8c438be6f715dde408f4958f6cb1755b100a40321d0d1")
    ]
)
