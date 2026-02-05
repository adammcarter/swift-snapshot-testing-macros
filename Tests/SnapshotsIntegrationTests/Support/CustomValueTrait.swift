import SnapshotTestingMacros
import Testing

extension SnapshotTrait where Self == CustomValueTrait {
  static func customValueTrait(value: String) -> Self {
    Self(value: value)
  }
}

extension SnapshotSuiteTrait where Self == CustomValueTrait {
  static func customValueTrait(value: String) -> Self {
    Self(value: value)
  }
}

extension SnapshotTestTrait where Self == CustomValueTrait {
  static func customValueTrait(value: String) -> Self {
    Self(value: value)
  }
}

struct CustomValueTrait: SnapshotSuiteTrait, SnapshotTestTrait, SnapshotTestScoping {
  let value: String

  @TaskLocal static var current = "default"

  func provideScope(
    performing function: () async throws -> Void
  ) async throws {
    try await CustomValueTrait.$current.withValue(value) {
      try await function()
    }
  }
}
