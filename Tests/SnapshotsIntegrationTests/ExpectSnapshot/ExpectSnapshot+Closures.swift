import SnapshotTestingMacros
import SwiftUI
import Testing

struct ExpectSnapshotClosureIntegrationTests {
  @Test
  func syncClosureNeedsNoEffects() {
    #expectSnapshot(named: "sync-closure") {
      Text("Synchronous closure")
    }
  }

  @Test
  func throwingClosureUsesTryOnly() throws {
    try #expectSnapshot(named: "throwing-closure") {
      Text(try makeThrowingClosureLabel())
    }
  }

  @Test
  func asyncClosureUsesAwaitOnly() async {
    await #expectSnapshot(named: "async-closure") {
      await Task.yield()
      return Text("Async closure")
    }
  }

  @Test
  func asyncThrowingClosureUsesTryAwaitOnlyWhenNeeded() async throws {
    try await #expectSnapshot(named: "async-throwing-closure") {
      Text(try await makeAsyncThrowingClosureLabel())
    }
  }
}

private func makeThrowingClosureLabel() throws -> String {
  "Throwing closure"
}

private func makeAsyncThrowingClosureLabel() async throws -> String {
  await Task.yield()
  return "Async throwing closure"
}
