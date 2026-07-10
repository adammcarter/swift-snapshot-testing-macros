@testable import SnapshotTestingMacros
import Testing

/// A user-shaped trait conforming to the `Testing` protocols directly (rather than the
/// package's `SnapshotSuiteTrait`/`SnapshotTestTrait` marker protocols) alongside
/// ``SnapshotTestScoping`` — the shape the legacy trait boxes previously failed to
/// disambiguate.
private struct DualConformingTrait: Testing.SuiteTrait, Testing.TestTrait, SnapshotTestScoping {
  let onPrepare: (@Sendable () -> Void)?

  init(onPrepare: (@Sendable () -> Void)? = nil) {
    self.onPrepare = onPrepare
  }

  var comments: [Comment] {
    ["dual-conforming comment"]
  }

  func prepare(for _: Test) async throws {
    onPrepare?()
  }

  func provideScope(
    performing function: () async throws -> Void
  ) async throws {
    try await function()
  }
}

struct TraitBoxTests {

  // The two boxing tests are compile-time regression guards: before the disambiguating
  // initializers existed, both expressions failed to compile with "ambiguous use of 'init'"
  // in macro-generated code the user never wrote.

  @Test
  func suiteTraitBoxAcceptsDirectSuiteTraitConformanceWithSnapshotScoping() {
    let box = __SuiteTraitBox(DualConformingTrait())

    #expect(box.wrapped is __TestScopingBox)
  }

  @Test
  func testTraitBoxAcceptsDirectTestTraitConformanceWithSnapshotScoping() {
    let box = __TestTraitBox(DualConformingTrait())

    #expect(box.wrapped is __TestScopingBox)
  }

  @Test
  func testScopingBoxForwardsComments() {
    let box = __TestScopingBox(DualConformingTrait())

    #expect(box.comments == ["dual-conforming comment"])
  }

  @Test
  func testScopingBoxForwardsPrepare() async throws {
    try await confirmation("prepare(for:) is forwarded to the wrapped trait") { prepared in
      let box = __TestScopingBox(DualConformingTrait(onPrepare: { prepared() }))

      try await box.prepare(for: #require(Test.current))
    }
  }
}
