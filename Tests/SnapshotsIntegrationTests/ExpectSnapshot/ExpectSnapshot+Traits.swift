// The committed references in __Snapshots__ are recorded on the iOS simulator (the CI
// integration job's platform). Artifact names carry no platform dimension, so running this
// suite on macOS renders via AppKit and can never match those references — gate it to UIKit
// like the legacy migration fixtures (and the repetition target). Dedicated AppKit runtime
// coverage lives in the ExpectSnapshot+AppKitRuntimeTests unit suites with macOS references.
#if canImport(UIKit)
import SwiftUI
import Testing

@testable import SnapshotTestingMacros

@Suite(
  .theme(.light),
  .sizes(.minimum),
  .record(.missing)
)
struct ExpectSnapshotTraitTests {
  @Test(
    .theme(.dark),
    .padding(.all, 16),
    .diffTool(.default)
  )
  func testLevelTraitsOverrideSuiteTraits() {
    #expectSnapshot(Text("Trait precedence"), named: "dark-padded")
  }

  @Test(.backgroundColor(.red))
  func backgroundColorTraitIsApplied() {
    #expectSnapshot(Text("Background color"), named: "background-red")
  }

  @Suite(.theme(.dark))
  struct Nested {
    @Test(
      .theme(.light),
      .theme(.dark)
    )
    func laterDuplicateTraitWins() {
      #expectSnapshot(Text("Nested precedence"), named: "nested-dark")
    }
  }
}
#endif
