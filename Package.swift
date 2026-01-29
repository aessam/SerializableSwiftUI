// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SerializableSwiftUI",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "PodcastData"
        ),
        .target(
            name: "ViewEngine"
        ),
        .target(
            name: "ActionSystem",
            dependencies: ["PodcastData", "ViewEngine"]
        ),
        .executableTarget(
            name: "SerializableSwiftUI",
            dependencies: ["ViewEngine", "ActionSystem", "PodcastData"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "ViewEngineTests",
            dependencies: ["ViewEngine", "ActionSystem", "PodcastData"]
        ),
    ]
)
