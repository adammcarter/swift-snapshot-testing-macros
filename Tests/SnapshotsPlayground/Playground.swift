import SnapshotTestingMacros
import SwiftUI
import Testing

// Playground: noun - A place where people can play.

@Suite
@SnapshotSuite(
  .disabled("Comment out this line to enable the tests")
)
struct MySnapshots {

  @SnapshotTest
  func myHelloView() -> some View {
    Text("Hello, snapshots!")
  }

  @SnapshotTest(
    .sizes(devices: .iPhoneX, fitting: .widthAndHeight)
  )
  @ViewBuilder
  func anotherView() -> some View {
    VStack {
      Text("Full iPhone snapshot")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.secondary)
  }
}
