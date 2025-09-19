import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest {

  @Suite
  struct Attributes {

    @Suite
    @SnapshotSuite
    struct TestParametersTests {

      @available(iOS 999.0, *)
      @SnapshotTest
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
