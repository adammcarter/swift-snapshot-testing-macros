import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite {

  @Suite
  @SnapshotSuite(
    .theme(.light)
  )
  struct AsyncThrows {

    @SnapshotTest
    func asyncOnly() async -> some View {
      snapshotText("async")
    }

    @SnapshotTest
    func throwsOnly() throws -> some View {
      snapshotText("throws")
    }

    @SnapshotTest
    func asyncThrows() async throws -> some View {
      snapshotText("async throws")
    }
  }
}
