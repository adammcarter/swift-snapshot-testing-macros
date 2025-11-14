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
      return Text("async")
    }

    @MainActor
    @SnapshotTest()
    func throwsOnly() throws -> some View {
      return Text("throws")
    }

    @MainActor
    @SnapshotTest()
    func asyncThrows() async throws -> some View {
      return Text("async throws")
    }
  }
}
