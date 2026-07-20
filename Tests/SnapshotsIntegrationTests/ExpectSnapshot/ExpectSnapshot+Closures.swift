// The committed references in __Snapshots__ are recorded on the iOS simulator (the CI
// integration job's platform). Artifact names carry no platform dimension, so running this
// suite on macOS renders via AppKit and can never match those references — gate it to UIKit
// like the legacy migration fixtures (and the repetition target). Dedicated AppKit runtime
// coverage lives in the ExpectSnapshot+AppKitRuntimeTests unit suites with macOS references.
#if canImport(UIKit)
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
#endif
