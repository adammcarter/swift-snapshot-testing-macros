import Testing

/// This is an implementation detail of the legacy `@SnapshotTest` macro expansion. Do not use
/// this type directly. It is `public` only for macro-generated code and is hidden from
/// documentation.
@_documentation(visibility: private)
// swiftlint:disable:next type_name
public struct __TestTraitBox: Testing.TestTrait {
  public let wrapped: any Testing.TestTrait

  public init(_ testTrait: any Testing.TestTrait) {
    self.wrapped = testTrait
  }

  public init(_ testScoping: any SnapshotTestScoping) {
    self.wrapped = __TestScopingBox(testScoping)
  }

  /// Disambiguates traits that conform to `Testing.TestTrait` directly (rather than via the
  /// package's ``SnapshotTestTrait`` marker protocol) alongside ``SnapshotTestScoping``.
  /// Without this overload, such traits match both the `any Testing.TestTrait` and the
  /// `any SnapshotTestScoping` initializers with equal specificity, producing an
  /// "ambiguous use of 'init'" error in macro-generated code the user never wrote.
  ///
  /// The ``SnapshotTestScoping`` conformance signals the trait wants the package's per-attempt
  /// scoping semantics, so it routes through ``__TestScopingBox`` like the marker-protocol
  /// shapes. The box forwards `comments` and `prepare(for:)`.
  public init(_ trait: any Testing.TestTrait & SnapshotTestScoping) {
    self.wrapped = __TestScopingBox(trait)
  }

  public init(_ trait: any SnapshotTestScoping & SnapshotTrait) {
    self.wrapped = __TestScopingBox(trait)
  }

  public init(_ testTrait: any SnapshotTestScoping & SnapshotTestTrait) {
    self.wrapped = __TestScopingBox(testTrait)
  }
}

extension __TestScopingBox: Testing.TestTrait {}
