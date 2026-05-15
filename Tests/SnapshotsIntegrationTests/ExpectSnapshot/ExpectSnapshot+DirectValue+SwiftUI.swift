import SnapshotTestingMacros
import SwiftUI
import Testing

struct ExpectSnapshotDirectValueSwiftUITests {
  @Test
  func swiftUiView() {
    #expectSnapshot(Text("Some SwiftUI text"))
  }

  @Test
  func namedSwiftUiView() {
    #expectSnapshot(Text("Some SwiftUI text"), named: "custom-name")
  }
}
