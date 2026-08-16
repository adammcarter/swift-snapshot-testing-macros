import Testing

/// This is an implementation detail of the legacy `@SnapshotSuite` macro expansion. Do not use
/// this type directly. It is `public` only for macro-generated code and is hidden from
/// documentation.
@_documentation(visibility: private)
// swiftlint:disable:next type_name
public struct __SuiteTraitBox: Testing.SuiteTrait {
  public let wrapped: any Testing.SuiteTrait

  public init(_ testTrait: any Testing.SuiteTrait) {
    self.wrapped = testTrait
  }

  public init(_ testScoping: any SnapshotTestScoping) {
    self.wrapped = __TestScopingBox(testScoping)
  }

  /// Disambiguates traits that conform to `Testing.SuiteTrait` directly (rather than via the
  /// package's ``SnapshotSuiteTrait`` marker protocol) alongside ``SnapshotTestScoping``.
  /// Without this overload, such traits match both the `any Testing.SuiteTrait` and the
  /// `any SnapshotTestScoping` initializers with equal specificity, producing an
  /// "ambiguous use of 'init'" error in macro-generated code the user never wrote.
  ///
  /// The ``SnapshotTestScoping`` conformance signals the trait wants the package's per-attempt
  /// scoping semantics, so it routes through ``__TestScopingBox`` like the marker-protocol
  /// shapes. The box forwards `comments` and `prepare(for:)`, but supplies its own recursive
  /// per-test-case scoping — a custom `isRecursive` on the wrapped trait is not honored.
  public init(_ trait: any Testing.SuiteTrait & SnapshotTestScoping) {
    self.wrapped = __TestScopingBox(trait)
  }

  public init(_ trait: any SnapshotTestScoping & SnapshotTrait) {
    self.wrapped = __TestScopingBox(trait)
  }

  public init(_ testTrait: any SnapshotTestScoping & SnapshotSuiteTrait) {
    self.wrapped = __TestScopingBox(testTrait)
  }
}

extension __TestScopingBox: Testing.SuiteTrait {
  /// Boxed scoping traits mirror ``SnapshotSuiteTrait``'s recursive application so their scope
  /// is provided once per descendant test case rather than once around the whole suite (which
  /// would share one per-attempt token across every test in the suite).
  public var isRecursive: Bool { true }
}
