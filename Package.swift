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
            url: "https://github.com/optikosprime/OptikosPrimeSDK-iOS/releases/download/0.0.9/OptikosPrimeSDK.xcframework.zip",
            checksum: "ec274249b518722892852b19953092c3ee8a6267eff36b7b5ea20972a0d7ea75")
    ]
)
