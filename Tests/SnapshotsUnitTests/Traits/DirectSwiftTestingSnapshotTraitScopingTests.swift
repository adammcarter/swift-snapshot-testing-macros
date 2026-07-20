#if os(macOS)
@testable import SnapshotTestingMacros
import Testing

@Suite(.theme(.dark))
struct DirectSwiftTestingTraitScopingTests {
  @Test
  func suiteTraitAppliesTaskLocalState() {
    #expect(ThemeSnapshotTrait.current == .dark)
  }

  @Test(.theme(.light), .theme(.dark))
  func laterDirectTraitsWin() {
    #expect(ThemeSnapshotTrait.current == .dark)
  }
}
#endif
