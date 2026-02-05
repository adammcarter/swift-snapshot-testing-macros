import Testing

@available(*, message: "This is an implementation detail. Do not use this type directly.")
// swiftlint:disable:next type_name
public struct __SuiteTraitBox: Testing.SuiteTrait {
  public let wrapped: any Testing.SuiteTrait

  public init(_ testTrait: any Testing.SuiteTrait) {
    self.wrapped = testTrait
  }

  public init(_ testScoping: any SnapshotTestScoping) {
    self.wrapped = __TestScopingBox(testScoping)
  }

  public init(_ trait: any SnapshotTestScoping & SnapshotTrait) {
    self.wrapped = __TestScopingBox(trait)
  }

  public init(_ testTrait: any SnapshotTestScoping & SnapshotSuiteTrait) {
    self.wrapped = __TestScopingBox(testTrait)
  }
}

extension __TestScopingBox: Testing.SuiteTrait {}
