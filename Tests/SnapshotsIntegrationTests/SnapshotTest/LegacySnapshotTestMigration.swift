#if canImport(UIKit)
import SnapshotTestingMacros
import SwiftUI
import Testing

@Suite
enum LegacySnapshotTestMigration {
  @Suite
  @SnapshotSuite(.theme(.light))
  struct SingleTest {
    @SnapshotTest(
      "Legacy named snapshot test",
      .strategy(.recursiveDescription)
    )
    func singleTest() -> some View {
      Text("legacy snapshot test migration")
    }

    @SnapshotTest(
      "Legacy configuration values test",
      .strategy(.recursiveDescription),
      configurationValues: [1, 2]
    )
    func configurationValues(value: Int) -> some View {
      Text("legacy snapshot configuration values: \(value)")
    }
  }
}
#endif
