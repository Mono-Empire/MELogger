// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MELogger",
    products: [
        .library(
            name: "MELogger",
            targets: ["MELogger"]
        ),
    ],
    targets: [
        .target(
            name: "MELogger",
            exclude: ["Samples"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "MELoggerTests",
            dependencies: ["MELogger"]
        ),
    ]
)
