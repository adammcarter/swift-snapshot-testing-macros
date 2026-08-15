// Compile-only regression fixtures for the UIKit/AppKit closure call shape.
//
// `#expectSnapshot { MyUIView() }` and `#expectSnapshot { MyViewController() }` are the
// platform counterparts of the SwiftUI builder, and they carry the same isolation contract:
// the builder is `@MainActor`, so it must compile from a `@MainActor` suite and a nonisolated
// one alike, in all four effect flavours. `ExpectSnapshot+SwiftUIIsolationCompileFixture`
// pins the SwiftUI half and `ExpectSnapshot+DirectValueEffectsCompileFixture` pins the direct
// value; this file is the platform closure half, which nothing else compiles from both
// isolations.
//
// These cells also guard the overload tie that `@_disfavoredOverload` resolves (see the
// header of `Assertion/expectSnapshot.swift`): every family's builder is `@MainActor` and the
// macro expands to one argument-label set, so a platform body must still reach a platform
// overload rather than tying with the SwiftUI ones.
//
// Unlike SwiftUI, these closures are not `@ViewBuilder` — UIKit and AppKit have no result
// builder — so each body is a single expression with an explicit `return` where it needs one.
//
// Compile-only: disabled, owning no reference artifacts, so this builds on macOS and iOS
// alike.
import SnapshotTestingMacros
import Testing

@MainActor
private func platformTitle() -> String {
  "probe"
}

private enum PlatformClosureFixtureError: Error {
  case sentinel
}

// Both factories read main-actor state before returning, so a builder that regressed to
// nonisolated could not call them from either suite — that is the property these cells pin.
@MainActor
private func makeDecoratedView() -> SnapshotView {
  _ = platformTitle()

  return SnapshotView()
}

@MainActor
private func makeDecoratedViewController() -> SnapshotViewController {
  _ = platformTitle()

  return SnapshotViewController()
}

@MainActor
@Suite(.disabled("Compile-only fixture for the platform closure call shape"))
struct PlatformClosureMainActorFixture {
  @Test
  func viewSync() {
    #expectSnapshot(named: "unused") { makeDecoratedView() }
  }

  @Test
  func viewThrowing() throws {
    try #expectSnapshot(named: "unused") { () throws -> SnapshotView in
      guard Bool.random() else { throw PlatformClosureFixtureError.sentinel }

      return makeDecoratedView()
    }
  }

  @Test
  func viewAsync() async {
    await #expectSnapshot(named: "unused") { () async -> SnapshotView in
      await Task.yield()

      return makeDecoratedView()
    }
  }

  @Test
  func viewAsyncThrowing() async throws {
    try await #expectSnapshot(named: "unused") { () async throws -> SnapshotView in
      try await Task.sleep(nanoseconds: 1)

      return makeDecoratedView()
    }
  }

  @Test
  func controllerSync() {
    #expectSnapshot(named: "unused") { makeDecoratedViewController() }
  }

  @Test
  func controllerThrowing() throws {
    try #expectSnapshot(named: "unused") { () throws -> SnapshotViewController in
      guard Bool.random() else { throw PlatformClosureFixtureError.sentinel }

      return makeDecoratedViewController()
    }
  }

  @Test
  func controllerAsync() async {
    await #expectSnapshot(named: "unused") { () async -> SnapshotViewController in
      await Task.yield()

      return makeDecoratedViewController()
    }
  }

  @Test
  func controllerAsyncThrowing() async throws {
    try await #expectSnapshot(named: "unused") { () async throws -> SnapshotViewController in
      try await Task.sleep(nanoseconds: 1)

      return makeDecoratedViewController()
    }
  }

  @Test
  func viewWithArgument() {
    #expectSnapshot(argument: "guest", named: "unused") { (_: String) -> SnapshotView in
      makeDecoratedView()
    }
  }

  @Test
  func controllerWithConfiguration() {
    let configuration = SnapshotConfiguration(name: "probe", value: "guest")

    #expectSnapshot(configuration, named: "unused") { (_: String) -> SnapshotViewController in
      makeDecoratedViewController()
    }
  }
}

@Suite(.disabled("Compile-only fixture for the platform closure call shape"))
struct PlatformClosureNonisolatedFixture {
  @Test
  func viewSync() {
    #expectSnapshot(named: "unused") { makeDecoratedView() }
  }

  @Test
  func viewThrowing() throws {
    try #expectSnapshot(named: "unused") { () throws -> SnapshotView in
      guard Bool.random() else { throw PlatformClosureFixtureError.sentinel }

      return makeDecoratedView()
    }
  }

  @Test
  func viewAsync() async {
    await #expectSnapshot(named: "unused") { () async -> SnapshotView in
      await Task.yield()

      return makeDecoratedView()
    }
  }

  @Test
  func viewAsyncThrowing() async throws {
    try await #expectSnapshot(named: "unused") { () async throws -> SnapshotView in
      try await Task.sleep(nanoseconds: 1)

      return makeDecoratedView()
    }
  }

  @Test
  func controllerSync() {
    #expectSnapshot(named: "unused") { makeDecoratedViewController() }
  }

  @Test
  func controllerThrowing() throws {
    try #expectSnapshot(named: "unused") { () throws -> SnapshotViewController in
      guard Bool.random() else { throw PlatformClosureFixtureError.sentinel }

      return makeDecoratedViewController()
    }
  }

  @Test
  func controllerAsync() async {
    await #expectSnapshot(named: "unused") { () async -> SnapshotViewController in
      await Task.yield()

      return makeDecoratedViewController()
    }
  }

  @Test
  func controllerAsyncThrowing() async throws {
    try await #expectSnapshot(named: "unused") { () async throws -> SnapshotViewController in
      try await Task.sleep(nanoseconds: 1)

      return makeDecoratedViewController()
    }
  }

  @Test
  func viewWithArgument() {
    #expectSnapshot(argument: "guest", named: "unused") { (_: String) -> SnapshotView in
      makeDecoratedView()
    }
  }

  @Test
  func controllerWithConfiguration() {
    let configuration = SnapshotConfiguration(name: "probe", value: "guest")

    #expectSnapshot(configuration, named: "unused") { (_: String) -> SnapshotViewController in
      makeDecoratedViewController()
    }
  }
}
