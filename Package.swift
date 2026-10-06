// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OptikosPrimeSDK",
    platforms: [
        .iOS("16.6")
    ],
    products: [
        .library(
            name: "OptikosPrimeSDK",
            targets: ["OptikosPrimeSDK", "OptikosPrimeSDKDependencies"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jurajantas/MediapipeSwiftPackage", from: "1.0.1")
    ],
    targets: [
        .target(
            name: "OptikosPrimeSDKDependencies",
            dependencies: [.product(name: "MediaPipeRuntime", package: "MediapipeSwiftPackage")]
        ),
        .binaryTarget(
            name: "OptikosPrimeSDK",
            url: "https://github.com/optikosprime/OptikosPrimeSDK-iOS/releases/download/0.0.4/OptikosPrimeSDK.xcframework.zip",
            checksum: "a938b10473d38a3d095760648b536fe32fc05fb0190c808cb6c53aae10131245")
    ]
)
