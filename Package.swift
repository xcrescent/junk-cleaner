// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JunkCleaner",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "JunkCleaner",
            path: "JunkCleaner",
            exclude: ["Info.plist"],
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
