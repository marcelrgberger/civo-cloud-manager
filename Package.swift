// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CivoAccessManager",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "CivoAccessManager",
            path: "Sources",
            exclude: ["Info.plist"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/Info.plist",
                ]),
            ]
        ),
    ]
)
