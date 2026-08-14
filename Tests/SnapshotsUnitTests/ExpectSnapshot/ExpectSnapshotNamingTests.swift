import Testing

@testable import SnapshotTestingMacros

struct ExpectSnapshotNamingTests {
  @Test
  func explicitNameWinsOverBaseName() {
    let context = SnapshotExecutionContext(function: "profileCard()")

    #expect(context.resolvedAssertionName(named: "hero") == "hero")
  }

  @Test
  func namesThatSanitizeIdenticallyGetDistinctSuffixes() {
    let context = SnapshotExecutionContext(function: "menu()")

    // "menu view" and "menu-view" both sanitize to the filename component
    // "menu-view", so the second assertion must be suffixed or its reference
    // file silently overwrites the first.
    #expect(context.resolvedAssertionName(named: "menu view") == "menu view")
    #expect(context.resolvedAssertionName(named: "menu-view") == "menu-view-2")
  }

  @Test
  func namesDifferingOnlyByCaseGetDistinctSuffixes() {
    let context = SnapshotExecutionContext(function: "menu()")

    // macOS filesystems are case-insensitive by default, so "Card.1.png" and "card.1.png"
    // are one file: the second assertion must be suffixed or it overwrites the first.
    #expect(context.resolvedAssertionName(named: "Card") == "Card")
    #expect(context.resolvedAssertionName(named: "card") == "card-2")
  }

  @Test
  func caseDifferencesThatSurviveSanitizationStillCollide() {
    let context = SnapshotExecutionContext(function: "menu()")

    // Sanitization preserves case, so "Min Size" and "min-size" stay distinct strings while
    // still landing on one reference file.
    #expect(context.resolvedAssertionName(named: "Min Size") == "Min Size")
    #expect(context.resolvedAssertionName(named: "min-size") == "min-size-2")
  }

  @Test
  func suffixSkipsCandidatesWhoseSanitizedFormIsAlreadyTaken() {
    let context = SnapshotExecutionContext(function: "menu()")

    #expect(context.resolvedAssertionName(named: "menu view") == "menu view")
    #expect(context.resolvedAssertionName(named: "menu view 2") == "menu view 2")
    // "menu-view" collides with "menu view"; the "-2" candidate collides with
    // "menu view 2", so it must land deterministically on "-3".
    #expect(context.resolvedAssertionName(named: "menu-view") == "menu-view-3")
  }

  @Test
  func slashPathNamesStayDistinctFromNamesThatSanitizeToTheSameComponent() {
    let context = SnapshotExecutionContext(function: "menu()")

    // "Menu/Item" resolves to folder "Menu" + file "Item" while "Menu Item"
    // stays a single "Menu-Item" file, so neither needs a suffix.
    #expect(context.resolvedAssertionName(named: "Menu/Item") == "Menu/Item")
    #expect(context.resolvedAssertionName(named: "Menu Item") == "Menu Item")
  }

  @Test
  func identicalRawNamesStillCountUpDeterministically() {
    let context = SnapshotExecutionContext(function: "menu()")

    #expect(context.resolvedAssertionName(named: "hero") == "hero")
    #expect(context.resolvedAssertionName(named: "hero") == "hero-2")
    #expect(context.resolvedAssertionName(named: "hero") == "hero-3")
  }
}
