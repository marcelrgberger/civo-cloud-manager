// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CivoCloudManager",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "CivoCloudManager",
            path: "Sources",
            exclude: ["Info.plist", "Localizable.xcstrings"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/Info.plist",
                ]),
            ]
        ),
        .testTarget(
            name: "CivoCloudManagerTests",
            dependencies: ["CivoCloudManager"],
            path: "Tests"
        ),
    ]
)
