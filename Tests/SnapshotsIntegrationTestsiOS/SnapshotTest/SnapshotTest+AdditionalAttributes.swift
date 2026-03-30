import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest {

  @Suite
  struct AdditionalAttributes {

    @Suite
    @SnapshotSuite
    struct TestParametersTests {

      @available(macOS 999.0, *)
      @available(iOS 999.0, *)
      @SnapshotTest(
        .record(.never)
      )
      func unavailable() -> some View {
        snapshotText("This test should be skipped")
      }

      @MainActor
      @SnapshotTest
      func explicitMainActor() -> some View {
        snapshotText("Explicit main actor")
      }
    }
  }
}
