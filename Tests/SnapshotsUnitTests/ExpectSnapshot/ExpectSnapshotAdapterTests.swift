import SwiftUI
import Testing

@testable import SnapshotTestingMacros

struct ExpectSnapshotAdapterTests {
  private enum ClosureFailure: Error {
    case sentinel
  }

  @Test
  func displayNamePrefersExplicitName() {
    let displayName = ExpectSnapshotAdapter.displayName(named: "custom-name", baseName: "myTest")

    #expect(displayName == "custom-name")
  }

  @Test
  func throwingClosureHelperRethrowsClosureErrors() {
    do {
      try __expectSnapshot(named: "unused") { () throws -> Text in
        throw ClosureFailure.sentinel
      }

      Issue.record("Expected sentinel error")
    }
    catch ClosureFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func asyncThrowingClosureHelperRethrowsClosureErrors() async {
    do {
      try await __expectSnapshot(named: "unused") { () async throws -> Text in
        await Task.yield()
        throw ClosureFailure.sentinel
      }

      Issue.record("Expected sentinel error")
    }
    catch ClosureFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }
}
