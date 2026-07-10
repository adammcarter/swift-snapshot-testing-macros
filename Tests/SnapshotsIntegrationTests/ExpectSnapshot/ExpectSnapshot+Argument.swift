// The committed references in __Snapshots__ are recorded on the iOS simulator (the CI
// integration job's platform). Artifact names carry no platform dimension, so running this
// suite on macOS renders via AppKit and can never match those references — gate it to UIKit
// like the legacy migration fixtures (and the repetition target). Dedicated AppKit runtime
// coverage lives in the ExpectSnapshot+AppKitRuntimeTests unit suites with macOS references.
#if canImport(UIKit)
import SnapshotTestingMacros
import SwiftUI
import Testing

enum CountState: Int, CaseIterable, Sendable {
  case zero
  case one
}

struct ExpectSnapshotArgumentIntegrationTests {
  @Test(arguments: CountState.allCases)
  func derivedArgumentName(state: CountState) {
    #expectSnapshot(argument: state) { state in
      Text("state-\(state.rawValue)")
    }
  }

  @Test(arguments: CountState.allCases)
  func explicitNameKeepsDerivedArgumentScope(state: CountState) {
    #expectSnapshot(argument: state, named: "custom") { state in
      Text("custom-\(state.rawValue)")
    }
  }
}
#endif
