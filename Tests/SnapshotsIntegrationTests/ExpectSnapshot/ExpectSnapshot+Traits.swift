import SnapshotTestingMacros
import SwiftUI
import Testing

@Suite(
  ThemeSnapshotTrait.theme(.light),
  SizesSnapshotTrait.sizes(.minimum),
  RecordSnapshotTrait.record(.missing)
)
@MainActor
struct ExpectSnapshotTraitTests {
  @Test(
    ThemeSnapshotTrait.theme(.dark),
    PaddingSnapshotTrait.padding(16),
    DiffToolSnapshotTrait.diffTool(.default)
  )
  func testLevelTraitsOverrideSuiteTraits() {
    #expectSnapshot(Text("Trait precedence"), named: "dark-padded")
  }

  @Test(BackgroundColorSnapshotTrait.backgroundColor(.red))
  func backgroundColorTraitIsApplied() {
    #expectSnapshot(Text("Background color"), named: "background-red")
  }

  @Suite(ThemeSnapshotTrait.theme(.dark))
  @MainActor
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
