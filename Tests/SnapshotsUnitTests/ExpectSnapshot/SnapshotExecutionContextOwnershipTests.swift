import Testing

@testable import SnapshotTestingMacros

struct SnapshotExecutionContextOwnershipTests {
  @Test
  func repeatedUnnamedAssertionsIncrementInsideOneContext() {
    let context = SnapshotExecutionContext(function: "profileCard()")

    #expect(context.resolvedAssertionName(named: nil) == "profileCard")
    #expect(context.resolvedAssertionName(named: nil) == "profileCard-2")
    #expect(context.resolvedAssertionName(named: nil) == "profileCard-3")
  }

  @Test
  func repeatedNamedAssertionsSuffixOnlyOnCollision() {
    let context = SnapshotExecutionContext(function: "profileCard()")

    #expect(context.resolvedAssertionName(named: "hero") == "hero")
    #expect(context.resolvedAssertionName(named: "hero") == "hero-2")
    #expect(context.resolvedAssertionName(named: "hero") == "hero-3")
  }

  @Test
  func generatedAndExplicitNamesDoNotCollide() {
    let context = SnapshotExecutionContext(function: "profileCard()")

    #expect(context.resolvedAssertionName(named: nil) == "profileCard")
    #expect(context.resolvedAssertionName(named: nil) == "profileCard-2")
    #expect(context.resolvedAssertionName(named: "profileCard-2") == "profileCard-2-2")
  }

  @Test
  func detachedTaskDoesNotInheritTaskLocalContext() async {
    let inherited = await TaskLocalSnapshotExecutionContext.$current.withValue(
      SnapshotExecutionContext(function: "profileCard()")
    ) {
      await Task.detached {
        TaskLocalSnapshotExecutionContext.current != nil
      }.value
    }

    #expect(inherited == false)
  }

  @Test
  func repeatedWithCurrentCallsReuseContextForTheActiveTest() {
    let first = TaskLocalSnapshotExecutionContext.withCurrent(function: "profileCard()") { $0 }
    let second = TaskLocalSnapshotExecutionContext.withCurrent(function: "profileCard()") { $0 }

    #expect(first === second)
  }

  @Test
  func childTaskGetsFreshCachedContext() async {
    let parent = TaskLocalSnapshotExecutionContext.withCurrent(function: "profileCard()") { $0 }
    let child = await Task {
      TaskLocalSnapshotExecutionContext.withCurrent(function: "profileCard()") { $0 }
    }.value

    #expect(parent !== child)
  }
}
