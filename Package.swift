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
            url: "https://github.com/optikosprime/OptikosPrimeSDK-iOS/releases/download/0.0.3/OptikosPrimeSDK.xcframework.zip",
            checksum: "24bdd4a7a74eb41c913663808f9d677df7af5ef3623c4ea6fe4ab1c86bfedf7d")
    ]
)
