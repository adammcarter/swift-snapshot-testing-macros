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
