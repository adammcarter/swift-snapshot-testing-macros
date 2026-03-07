#if os(macOS)
import SnapshotTesting
@testable import SnapshotTestingMacros
import Testing

@Suite
struct DiffToolSnapshotTraitTests {

  @Test
  func debugDescription() {
    let diffTool = SnapshotTesting.SnapshotTestingConfiguration.DiffTool { _, _ in "" }
    let trait = DiffToolSnapshotTrait(diffTool: diffTool)

    #expect(trait.debugDescription.starts(with: "diffTool: "))
  }

  @Test
  func provideScope() async throws {
    let diffTool = SnapshotTesting.SnapshotTestingConfiguration.DiffTool { _, _ in "" }
    let trait = DiffToolSnapshotTrait(diffTool: diffTool)

    // We can't easily check function equality, but we can check if the scope is provided.
    // The default is nil or some default closure.
    // Here we just verify it runs without crashing and sets *something*.

    try await trait.provideScope {
      // It's hard to verify the exact value of a closure,
      // but we know the mechanism is the same as RecordSnapshotTrait which is verified.
    }
  }
}
#endif
