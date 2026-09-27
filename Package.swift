// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AutoTranslator",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "AutoTranslator",
            path: "Sources/AutoTranslator",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
