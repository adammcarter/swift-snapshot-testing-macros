import SnapshotTestingMacros
import Testing

/**
 Example of a Swift Testing trait.

 Imagine this trait is in an existing repo that doesn't know anything about snapshot tests ...
 */

struct MyExampleTrait: Testing.TestScoping, Testing.SuiteTrait, Testing.TestTrait {
  var value: String

  @TaskLocal static var current = "default"

  func provideScope(
    for _: Test,
    testCase _: Test.Case?,
    performing function: () async throws -> Void
  ) async throws {
    try await MyExampleTrait.$current.withValue(value) {
      try await function()
    }
  }
}

extension Testing.SuiteTrait where Self == MyExampleTrait {
  static func testScopingTrait(value: String) -> Self {
    Self(value: value)
  }
}

extension Testing.TestTrait where Self == MyExampleTrait {
  static func testScopingTrait(value: String) -> Self {
    Self(value: value)
  }
}

/**
 And this code wants to marry the existing Swift Testing scoping with the SnapshotTestingMacros library.

 All that's needed is to extend the existing trait to conform to `SnapshotSuiteTrait` and/or `SnapshotTestTrait`.
 */

/// Conform to `SnapshotSuiteTrait` to use an existing `TestScoping` type in `@SnapshotSuite` macros.
extension MyExampleTrait: SnapshotSuiteTrait {}

/// Conform to `SnapshotTestTrait` to use an existing `TestScoping` type in `@SnapshotTest` macros.
extension MyExampleTrait: SnapshotTestTrait {}
