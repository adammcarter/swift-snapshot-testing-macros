import SnapshotTestingMacros
import SwiftUI
import Testing

struct ExpectSnapshotDirectValueSwiftUITests {
  @Test
  func swiftUiView() {
    #expectSnapshot(Text("Some SwiftUI text"))
  }
}
