// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SerializableSwiftUI",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
    ],
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
        .target(
            name: "EditorUI",
            dependencies: [
                "ViewEngine",
                "ActionSystem",
                .product(name: "OrderedCollections", package: "swift-collections"),
            ]
        ),
        .executableTarget(
            name: "SerializableSwiftUI",
            dependencies: ["ViewEngine", "ActionSystem", "PodcastData", "EditorUI"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "ViewEngineTests",
            dependencies: ["ViewEngine", "ActionSystem", "PodcastData"]
        ),
    ]
)
