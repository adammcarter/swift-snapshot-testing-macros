import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite {

  @Suite
  struct AdditionalAttributes {

    @MainActor
    @Suite
    @SnapshotSuite(.sizes(.minimum, scale: 2.0))
    struct TestParametersTests {

      @SnapshotTest
      func explicitMainActor() -> some View {
        Text("Explicit main actor")
      }
    }
  }
}
