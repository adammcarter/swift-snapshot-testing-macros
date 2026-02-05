import Testing

@available(*, message: "This is an implementation detail. Do not use this type directly.")
// swiftlint:disable:next type_name
public struct __TestTraitBox: Testing.TestTrait {
  public let wrapped: any Testing.TestTrait

  public init(_ testTrait: any Testing.TestTrait) {
    self.wrapped = testTrait
  }

  public init(_ testScoping: any SnapshotTestScoping) {
    self.wrapped = __TestScopingBox(testScoping)
  }

  public init(_ trait: any SnapshotTestScoping & SnapshotTrait) {
    self.wrapped = __TestScopingBox(trait)
  }

  public init(_ testTrait: any SnapshotTestScoping & SnapshotTestTrait) {
    self.wrapped = __TestScopingBox(testTrait)
  }
}

extension __TestScopingBox: Testing.TestTrait {}
