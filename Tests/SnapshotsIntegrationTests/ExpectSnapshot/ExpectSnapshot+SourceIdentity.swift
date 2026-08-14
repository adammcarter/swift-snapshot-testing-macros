// The committed references in __Snapshots__ are recorded on the iOS simulator (the CI
// integration job's platform). Artifact names carry no platform dimension, so running this
// suite on macOS renders via AppKit and can never match those references.
#if canImport(UIKit)
import SnapshotTestingMacros
import SwiftUI
import Testing

struct SourceIdentitySnapshotTests {
  @Test
  func namedCallSitesUseExplicitReferences() {
    #expectSnapshot(Text("first traitless call site"), named: "first")
    #expectSnapshot(Text("second traitless call site"), named: "second")
  }
}
#endif
