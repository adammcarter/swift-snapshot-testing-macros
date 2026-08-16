import Testing

@testable import SnapshotTestingMacros

struct SnapshotExecutionContextTests {
  @Test
  func baseNameComesFromFunction() {
    let context = SnapshotExecutionContext(function: "swiftUiView()")

    #expect(context.baseName == "swiftUiView")
  }
}
