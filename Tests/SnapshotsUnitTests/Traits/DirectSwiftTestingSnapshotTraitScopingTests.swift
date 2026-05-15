#if os(macOS)
@testable import SnapshotTestingMacros
import Testing

@Suite(ThemeSnapshotTrait.theme(.dark))
struct DirectSwiftTestingSnapshotTraitScopingTests {
  @Test
  func suiteTraitAppliesTaskLocalState() {
    #expect(ThemeSnapshotTrait.current == .dark)
  }

  @Test(ThemeSnapshotTrait.theme(.light), ThemeSnapshotTrait.theme(.dark))
  func laterDirectTraitsWin() {
    #expect(ThemeSnapshotTrait.current == .dark)
  }
}
#endif
