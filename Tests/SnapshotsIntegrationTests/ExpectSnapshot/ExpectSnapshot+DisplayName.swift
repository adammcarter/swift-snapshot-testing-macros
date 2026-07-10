// The committed references in __Snapshots__ are recorded on the iOS simulator (the CI
// integration job's platform). Artifact names carry no platform dimension, so running this
// suite on macOS renders via AppKit and can never match those references — gate it to UIKit
// like the legacy migration fixtures (and the repetition target). Dedicated AppKit runtime
// coverage lives in the ExpectSnapshot+AppKitRuntimeTests unit suites with macOS references.
#if canImport(UIKit)
import SnapshotTestingMacros
import SwiftUI
import Testing

struct ExpectSnapshotDisplayNameTests {
  @Test("Profile card")
  func profileCard() {
    #expectSnapshot(Text("Display name stays in test output only"))
  }
}
#endif
