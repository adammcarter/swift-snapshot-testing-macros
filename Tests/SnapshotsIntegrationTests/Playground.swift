import SnapshotTestingMacros
import SwiftUI
import Testing

// Playground: noun - A place where people can play.

@SnapshotSuite("My Snapshots")
@Suite
struct MySnapshots {
  @SnapshotTest
  func myView() -> some View {
    Text("Snapshot me")
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
