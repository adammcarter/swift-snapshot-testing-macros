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
      Text("async")
    }

    @SnapshotTest
    func throwsOnly() throws -> some View {
      Text("throws")
    }

    @SnapshotTest
    func asyncThrows() async throws -> some View {
      Text("async throws")
    }
  }
}
