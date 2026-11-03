// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MillariumCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MillariumCore", targets: ["MillariumCore"]),
        .executable(name: "millarium-cli", targets: ["millarium-cli"])
    ],
    targets: [
        .target(
            name: "MillariumCore",
            path: "Sources/MillariumCore"
        ),
        .executableTarget(
            name: "millarium-cli",
            dependencies: ["MillariumCore"],
            path: "Sources/millarium-cli"
        ),
        .testTarget(
            name: "MillariumCoreTests",
            dependencies: ["MillariumCore"],
            path: "Tests/MillariumCoreTests"
        )
    ]
)
