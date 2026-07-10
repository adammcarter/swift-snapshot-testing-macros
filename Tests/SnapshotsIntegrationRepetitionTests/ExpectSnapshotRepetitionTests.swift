// The committed references in __Snapshots__ are recorded on the iOS simulator (the CI
// repetition job's platform). Artifact names carry no platform dimension, so running this
// suite on macOS renders via AppKit and can never match those references — gate it to UIKit
// like its legacy sibling. Dedicated macOS repetition coverage needs its own reference set.
#if canImport(UIKit)
import SnapshotTestingMacros
import SwiftUI
import Testing

@Suite(ThemeSnapshotTrait.theme(.light))
struct ExpectSnapshotRepetitionTests {
  @Test
  func singular() {
    #expectSnapshot(Text("singular reference image"))
    #expectSnapshot(Text("singular reference image again"))
  }

  @Test
  func helperWrappedUnnamedAssertionsReuseTheSameContext() {
    #expectSnapshot(Text("top level unnamed"))
    helperWrappedUnnamedAssertion()
  }

  @Test(arguments: [
    SnapshotConfiguration(name: "1", value: 1),
    SnapshotConfiguration(name: "2", value: 2),
    SnapshotConfiguration(name: "3", value: 3),
  ])
  func configurations(configuration: SnapshotConfiguration<Int>) {
    #expectSnapshot(configuration) { int in
      Text("configurations reference image: \(int)")
    }
  }

  private func helperWrappedUnnamedAssertion() {
    #expectSnapshot(Text("helper unnamed"))
  }
}
#endif
