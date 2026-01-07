// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Glassboard",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Glassboard",
            path: "Sources/Glassboard",
            // Explicitly link Carbon (implied by Cocoa usually, but strictly speaking)
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("AppKit")
            ]
        )
    ]
)
