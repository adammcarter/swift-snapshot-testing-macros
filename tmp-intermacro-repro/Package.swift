// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SwiftTestingInterMacroRepro",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "SwiftTestingInterMacroRepro",
            targets: ["SwiftTestingInterMacroRepro"]
        ),
    ],
    dependencies: [
        .package(path: "../.build/checkouts/swift-syntax"),
    ],
    targets: [
        .macro(
            name: "SwiftTestingInterMacroReproMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Sources/tmp-intermacro-reproMacros"
        ),
        .target(
            name: "SwiftTestingInterMacroRepro",
            dependencies: ["SwiftTestingInterMacroReproMacros"],
            path: "Sources/tmp-intermacro-repro"
        ),
        .testTarget(
            name: "SwiftTestingInterMacroReproTests",
            dependencies: ["SwiftTestingInterMacroRepro"],
            path: "Tests/tmp-intermacro-reproTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
