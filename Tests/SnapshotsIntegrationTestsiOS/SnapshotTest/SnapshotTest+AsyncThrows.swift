import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest {

  @Suite
  @SnapshotSuite(
    .theme(.light)
  )
  struct AsyncThrows {

    @MainActor
    @SnapshotTest()
    func asyncOnly() async -> some View {
      snapshotText("async")
    }

    @MainActor
    @SnapshotTest()
    func throwsOnly() throws -> some View {
      snapshotText("throws")
    }

    @MainActor
    @SnapshotTest()
    func asyncThrows() async throws -> some View {
      snapshotText("async throws")
    }
  }
}
