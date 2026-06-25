// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CodexEnterGuard",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "CodexEnterGuardCore", targets: ["CodexEnterGuardCore"]),
        .executable(name: "CodexSendGuard", targets: ["CodexSendGuard"]),
    ],
    targets: [
        .target(name: "CodexEnterGuardCore"),
        .executableTarget(
            name: "CodexSendGuard",
            dependencies: ["CodexEnterGuardCore"],
            path: "Sources/CodexEnterGuard"
        ),
        .testTarget(
            name: "CodexEnterGuardCoreTests",
            dependencies: ["CodexEnterGuardCore"]
        ),
    ]
)
