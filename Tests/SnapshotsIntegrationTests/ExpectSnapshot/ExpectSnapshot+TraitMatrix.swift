// The committed references in __Snapshots__ are recorded on the iOS simulator (the CI
// integration job's platform). Artifact names carry no platform dimension, so running this
// suite on macOS renders via AppKit and can never match those references.
#if canImport(UIKit)
import SnapshotTestingMacros
import SwiftUI
import Testing

struct TraitMatrixSnapshotTests {
  @Test(
    .theme(.light),
    .sizes(.minimum),
    .backgroundColor(.red),
    .padding(8)
  )
  func swiftUIBackgroundThenPadding() {
    #expectSnapshot(Text("trait order"), named: "swiftui-background-padding")
  }

  @Test(
    .theme(.light),
    .sizes(width: 160, height: 80),
    .backgroundColor(.red),
    .padding(8)
  )
  func decoratedUIKitViewUsesFixedSize() {
    #expectSnapshot(makeLabel("UIKit decorated fixed size"), named: "uikit-decorated-fixed")
  }

  @Test(
    .theme(.light),
    .sizes(.minimum),
    .strategy(.recursiveDescription)
  )
  func uiKitViewSupportsRecursiveDescription() {
    #expectSnapshot(makeLabel("UIKit recursive description"), named: "uikit-recursive")
  }
}
#endif
