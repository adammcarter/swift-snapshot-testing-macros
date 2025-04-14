// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-snapshot-testing-macros",
  platforms: [
    .macOS(.v11),
    .iOS(.v14),
  ],
  products: [
    .library(
      name: "SnapshotTestingMacros",
      targets: ["SnapshotTestingMacros"]
    ),
    .executable(name: "SnapshotsClient", targets: ["SnapshotsClient"]),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax", exact: "601.0.1"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.18.3"),
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", exact: "0.6.2"),
  ],
  targets: [
    /*
     This is where all of the source code parsing happens to convert from raw macro to expanded code.

     For example, converting '@SnapshotSuite("My tests")' in to the code you see when expanding the macro in place.

     It's important to remember the expanded macro code is not run in this target, this target acts more as a developer writing the code.

     Another way to think about this target is like a protocol definition, there's no real implementation here but we set out the contract.
     */
    .macro(
      name: "SnapshotsMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),

    /*
     This is the implementation for the expanded macro code.

     This target will read the expanded macro and 'convert' it from plain text in to fully functioning Swift essentially acting as a compiler.

     It's important that any code expanded from 'SnapshotsMacros' is understood by 'SnapshotTestingMacros'

     Where the above target is like a protocol, 'SnapshotTestingMacros' acts as our implementation of the protocol.
     */
    .target(
      name: "SnapshotTestingMacros",
      dependencies: [
        "SnapshotsMacros",

        .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
      ]

      // TODO: Commented out until Xcode 16.3
      //      ,
      //      swiftSettings: [
      //        .enableUpcomingFeature("StrictConcurrency")
      //      ]
    ),

    // A client of the library, which is able to use the macro in its own code.
    .executableTarget(
      name: "SnapshotsClient",
      dependencies: [
        "SnapshotTestingMacros"
      ]
    ),

    /*
     This test target tests the *implementation* of the macro, making sure the expanded code is correct for a given macro.

     This must be run on macOS.
     */
    .testTarget(
      name: "SnapshotsUnitTests",
      dependencies: [
        "SnapshotTestSupport",
        "SnapshotTestingMacros",
        "SnapshotsMacros",
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
        .product(name: "MacroTesting", package: "swift-macro-testing"),
      ]
    ),

    /*
     A test target for testing the suite during development.

     Because our macro create tests in the form of snapshot tests, we can create integration tests using the snapshot images as our references.

     Usually in a macro we'd just use 'main.swift' to test and debug the macro while developing, but we need to attach our macro to a test target to be able run the tests the macro creates, this is that test target.

     This test target simply wraps the SnapshotTestingMacros library so we can run those generated tests.

     This must be run on an iPhone 16 running iOS 18.4 to guarantee matching the reference images with those generated during testing.
     */
    .testTarget(
      name: "SnapshotsIntegrationTests",
      dependencies: [
        "SnapshotTestSupport",
        "SnapshotTestingMacros",
        "SnapshotsMacros",
      ],
      exclude: [
        "__Snapshots__",
        "SnapshotSuite/__Snapshots__",
        "SnapshotSuite/Traits/__Snapshots__",
        "SnapshotTest/__Snapshots__",
        "SnapshotTest/Traits/__Snapshots__",
        "SnapshotTest/Configurations/__Snapshots__",
      ]
    ),

    /*
     Support target for tests.
     */
    .target(
      name: "SnapshotTestSupport",
      path: "Tests/SnapshotTestSupport"
    ),
  ]
)
