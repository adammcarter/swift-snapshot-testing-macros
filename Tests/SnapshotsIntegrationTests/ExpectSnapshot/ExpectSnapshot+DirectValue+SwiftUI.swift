// The committed references in __Snapshots__ are recorded on the iOS simulator (the CI
// integration job's platform). Artifact names carry no platform dimension, so running this
// suite on macOS renders via AppKit and can never match those references — gate it to UIKit
// like the legacy migration fixtures (and the repetition target). Dedicated AppKit runtime
// coverage lives in the ExpectSnapshot+AppKitRuntimeTests unit suites with macOS references.
#if canImport(UIKit)
import SnapshotTestingMacros
import SwiftUI
import Testing

struct ExpectSnapshotDirectValueSwiftUITests {
  @Test
  func swiftUiView() {
    #expectSnapshot(Text("Some SwiftUI text"), named: "swiftUiView")
  }

  @Test
  func namedSwiftUiView() {
    #expectSnapshot(Text("Some SwiftUI text"), named: "custom-name")
  }
}
#endif
