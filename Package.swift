// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AgentSDK",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "AgentSDK",
            targets: ["AgentSDK"]
        ),
    ],
    targets: [
        .target(
            name: "AgentSDK",
            path: "Sources"
        ),
        .testTarget(
            name: "AgentSDKTests",
            dependencies: ["AgentSDK"],
            path: "Tests"
        ),
    ]
)
