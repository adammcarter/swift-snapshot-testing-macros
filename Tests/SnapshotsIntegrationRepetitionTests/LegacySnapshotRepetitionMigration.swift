#if canImport(UIKit)
import SnapshotTestingMacros
import SwiftUI
import Testing

@Suite
@SnapshotSuite(
  .theme(.light),
  .strategy(.recursiveDescription)
)
struct LegacySnapshotRepetitionMigration {
  @SnapshotTest
  func singular() -> some View {
    Text("legacy repetition singular")
  }

  @SnapshotTest(
    configurations: (1 ... 3)
      .map {
        .init(name: "\($0)", value: $0)
      }
  )
  func configurations(int: Int) -> some View {
    Text("legacy repetition configuration: \(int)")
  }
}
#endif
