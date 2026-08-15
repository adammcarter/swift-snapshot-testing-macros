// Compile-only regression fixtures for the direct-value form's effect matrix.
//
// The direct value used to be spliced into a sync `@autoclosure` parameter, so the only effect
// it could carry was a `try` sitting at the very root of the expression — and only because the
// macro detected that `try` syntactically and appended a `throwingMarker: ()` argument to route
// the call to a throwing autoclosure overload. Everything else failed inside a macro expansion
// buffer the author cannot open:
//
//   #expectSnapshot(await makeView())              'async' call in an autoclosure that does not
//   #expectSnapshot(try await makeView())          support concurrency
//   #expectSnapshot(Wrapper(inner: try make()))    Call can throw, but it is executed in a
//                                                  non-throwing autoclosure
//
// The direct value is now spliced into the `makeValue:` builder closure instead, so the effects
// belong to the closure and the compiler picks the matching overload itself. These cells pin
// that every effect shape composes, for SwiftUI and platform values alike, from a `@MainActor`
// suite and a nonisolated one — the direct value is evaluated inside the builders' main-actor
// hop, so both isolations have to work.
//
// These suites exist to be compiled, not to record or compare reference artifacts: they are
// disabled and own no references.
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import SnapshotTestingMacros
import SwiftUI
import Testing

@MainActor
private func directValueTitle() -> String {
  "direct"
}

@MainActor
private func throwingDirectValueView() throws -> Text {
  Text(directValueTitle())
}

@MainActor
private func awaitingDirectValueView() async -> Text {
  await Task.yield()

  return Text(directValueTitle())
}

@MainActor
private func awaitingThrowingDirectValueView() async throws -> Text {
  await Task.yield()

  return Text(directValueTitle())
}

private struct DirectValueEffectsWrapper: View {
  let inner: Text

  var body: some View {
    inner
  }
}

@MainActor
private func makePlatformView() -> SnapshotView {
  SnapshotView()
}

@MainActor
private func throwingPlatformView() throws -> SnapshotView {
  SnapshotView()
}

@MainActor
private func awaitingThrowingPlatformView() async throws -> SnapshotView {
  await Task.yield()

  return SnapshotView()
}

@MainActor
private func makePlatformViewController() -> SnapshotViewController {
  SnapshotViewController()
}

@MainActor
private func makeAwaitingThrowingPlatformViewController() async throws -> SnapshotViewController {
  await Task.yield()

  return SnapshotViewController()
}

@MainActor
@Suite(.disabled("Compile-only fixture for direct-value effects"))
struct DirectValueEffectsMainActorFixture {
  @Test
  func plain() {
    #expectSnapshot(Text(directValueTitle()), named: "unused")
  }

  @Test
  func throwing() throws {
    try #expectSnapshot(try throwingDirectValueView(), named: "unused")
  }

  @Test
  func awaiting() async {
    await #expectSnapshot(await awaitingDirectValueView(), named: "unused")
  }

  @Test
  func awaitingThrowing() async throws {
    try await #expectSnapshot(try await awaitingThrowingDirectValueView(), named: "unused")
  }

  @Test
  func nestedThrowing() throws {
    try #expectSnapshot(
      DirectValueEffectsWrapper(inner: try throwingDirectValueView()),
      named: "unused"
    )
  }

  @Test
  func optionalTry() {
    #expectSnapshot(try? throwingDirectValueView(), named: "unused")
  }

  @Test
  func forcedTry() {
    // swiftlint:disable:next force_try
    #expectSnapshot(try! throwingDirectValueView(), named: "unused")
  }

  @Test
  func platformView() {
    #expectSnapshot(makePlatformView(), named: "unused")
  }

  @Test
  func throwingPlatformValue() throws {
    try #expectSnapshot(try throwingPlatformView(), named: "unused")
  }

  @Test
  func awaitingThrowingPlatformValue() async throws {
    try await #expectSnapshot(try await awaitingThrowingPlatformView(), named: "unused")
  }

  @Test
  func platformViewController() {
    #expectSnapshot(makePlatformViewController(), named: "unused")
  }

  @Test
  func awaitingThrowingPlatformViewController() async throws {
    try await #expectSnapshot(
      try await makeAwaitingThrowingPlatformViewController(),
      named: "unused"
    )
  }
}

@Suite(.disabled("Compile-only fixture for direct-value effects"))
struct DirectValueEffectsNonisolatedFixture {
  @Test
  func plain() {
    #expectSnapshot(Text(directValueTitle()), named: "unused")
  }

  @Test
  func throwing() throws {
    try #expectSnapshot(try throwingDirectValueView(), named: "unused")
  }

  @Test
  func awaiting() async {
    await #expectSnapshot(await awaitingDirectValueView(), named: "unused")
  }

  @Test
  func awaitingThrowing() async throws {
    try await #expectSnapshot(try await awaitingThrowingDirectValueView(), named: "unused")
  }

  @Test
  func nestedThrowing() throws {
    try #expectSnapshot(
      DirectValueEffectsWrapper(inner: try throwingDirectValueView()),
      named: "unused"
    )
  }

  @Test
  func platformView() {
    #expectSnapshot(makePlatformView(), named: "unused")
  }

  @Test
  func awaitingThrowingPlatformValue() async throws {
    try await #expectSnapshot(try await awaitingThrowingPlatformView(), named: "unused")
  }

  @Test
  func platformViewController() {
    #expectSnapshot(makePlatformViewController(), named: "unused")
  }

  @Test
  func awaitingThrowingPlatformViewController() async throws {
    try await #expectSnapshot(
      try await makeAwaitingThrowingPlatformViewController(),
      named: "unused"
    )
  }
}
