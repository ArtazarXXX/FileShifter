// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FileShifter",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "FileShifter", targets: ["FileShifter"])
    ],
    targets: [
        .executableTarget(
            name: "FileShifter",
            path: "Sources/FileShifter"
        )
    ]
)
