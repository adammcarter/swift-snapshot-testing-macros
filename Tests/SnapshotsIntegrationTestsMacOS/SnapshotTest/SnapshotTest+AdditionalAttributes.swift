import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest {

  @Suite
  struct AdditionalAttributes {

    @Suite
    @SnapshotSuite(.sizes(.minimum, scale: 2.0))
    struct TestParametersTests {

      @available(macOS 999.0, *)
      @available(iOS 999.0, *)
      @SnapshotTest(
        .record(.never)
      )
      func unavailable() -> some View {
        Text("This test should be skipped")
      }

      @MainActor
      @SnapshotTest
      func explicitMainActor() -> some View {
        Text("Explicit main actor")
      }
    }
  }
}
