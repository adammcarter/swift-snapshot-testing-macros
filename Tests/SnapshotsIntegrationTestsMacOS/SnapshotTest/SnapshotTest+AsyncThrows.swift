import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest {

  @Suite
  @SnapshotSuite(
    .sizes(.minimum, scale: 2.0),
    .theme(.light)
  )
  struct AsyncThrows {

    @MainActor
    @SnapshotTest()
    func asyncOnly() async -> some View {
      Text("async")
    }

    @MainActor
    @SnapshotTest()
    func throwsOnly() throws -> some View {
      Text("throws")
    }

    @MainActor
    @SnapshotTest()
    func asyncThrows() async throws -> some View {
      Text("async throws")
    }
  }
}
