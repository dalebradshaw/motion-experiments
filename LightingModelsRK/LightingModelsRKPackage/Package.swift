// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LightingModelsRKFeature",
    platforms: [.macOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LightingModelsRKFeature",
            targets: ["LightingModelsRKFeature"]
        ),
    ],
    targets: [
        .target(
            name: "LightingModelsRKFeature",
            linkerSettings: [
                .linkedFramework("RealityKit"),
                .linkedFramework("Metal"),
            ]
        ),
        .testTarget(
            name: "LightingModelsRKFeatureTests",
            dependencies: [
                "LightingModelsRKFeature"
            ]
        ),
    ]
)
