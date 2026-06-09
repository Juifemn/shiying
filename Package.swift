// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Shiying",
    defaultLocalization: "zh-Hans",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "Shiying",
            targets: ["Shiying"]
        )
    ],
    targets: [
        .target(
            name: "ShiyingCore",
            path: "Sources/ShiyingCore"
        ),
        .executableTarget(
            name: "Shiying",
            dependencies: ["ShiyingCore"],
            path: "Sources/Shiying"
        )
    ]
)
