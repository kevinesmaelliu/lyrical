// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Lyrical",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Lyrical", targets: ["Lyrical"]),
    ],
    targets: [
        .executableTarget(
            name: "Lyrical",
            path: "Sources/Lyrical"
        ),
    ]
)
