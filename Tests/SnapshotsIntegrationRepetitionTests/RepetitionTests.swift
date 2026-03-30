import SnapshotTestingMacros
import SwiftUI
import Testing

@Suite
@SnapshotSuite(
  .theme(.light)
)
struct RepetitionTests {

  @SnapshotTest
  func singular() -> some View {
    snapshotText("singular reference image")
  }

  @SnapshotTest(
    configurations: (1 ... 3)
      .map {
        .init(name: "\($0)", value: $0)
      }
  )
  func configurations(int: Int) -> some View {
    snapshotText("configurations reference image: \(int)")
  }
}
