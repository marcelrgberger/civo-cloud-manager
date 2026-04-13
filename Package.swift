// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CivoCloudManager",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "CivoCloudManager",
            path: "CivoCloudManager",
            exclude: [
                "Info.plist",
                "Assets.xcassets",
                "Localizable.xcstrings",
                "PrivacyInfo.xcprivacy",
                "CivoCloudManager.entitlements",
                "CivoCloudManager.storekit",
                "en.lproj",
                "de.lproj",
                "es.lproj",
                "fr.lproj",
                "it.lproj",
                "nl.lproj",
                "pl.lproj",
                "pt.lproj",
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "CivoCloudManager/Info.plist",
                ]),
            ]
        ),
        .testTarget(
            name: "CivoCloudManagerTests",
            dependencies: ["CivoCloudManager"],
            path: "CivoCloudManagerTests"
        ),
    ]
)
