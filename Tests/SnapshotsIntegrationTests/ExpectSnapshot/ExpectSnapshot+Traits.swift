import SwiftUI
import Testing

@testable import SnapshotTestingMacros

@Suite(
  ThemeSnapshotTrait.theme(.light),
  SizesSnapshotTrait.sizes(.minimum),
  RecordSnapshotTrait.record(.missing)
)
struct ExpectSnapshotTraitTests {
  @Test(
    ThemeSnapshotTrait.theme(.dark),
    PaddingSnapshotTrait(edges: .all, length: 16),
    DiffToolSnapshotTrait.diffTool(.default)
  )
  func testLevelTraitsOverrideSuiteTraits() {
    #expectSnapshot(Text("Trait precedence"), named: "dark-padded")
  }

  @Test(BackgroundColorSnapshotTrait(backgroundColor: .red))
  func backgroundColorTraitIsApplied() {
    #expectSnapshot(Text("Background color"), named: "background-red")
  }

  @Suite(ThemeSnapshotTrait.theme(.dark))
  struct Nested {
    @Test(
      ThemeSnapshotTrait.theme(.light),
      ThemeSnapshotTrait.theme(.dark)
    )
    func laterDuplicateTraitWins() {
      #expectSnapshot(Text("Nested precedence"), named: "nested-dark")
    }
  }
}
