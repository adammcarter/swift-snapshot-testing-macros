// Compile-only regression fixtures for the SwiftUI builder's `@ViewBuilder` body shapes.
//
// `@ViewBuilder` has to sit on the runtime `__expectSnapshot` overload, not only on the macro
// declaration: the expansion re-type-checks its argument against the runtime function, so a
// builder attribute that lives only on the macro relocates the failure into the expansion
// buffer instead of fixing it. It sits on both here — the macro declaration so the public
// surface describes itself, the runtime overload so the transform actually applies.
//
// Each cell below is a body shape that does not type-check without the result-builder
// transform: several sibling views, `if` / `else`, a bare `if`, `switch`, and `ForEach`,
// across all four effects and the bare, `argument:`, `SnapshotConfiguration`, and tuple
// parameterisations.
//
// The effectful cells also pin the `@_disfavoredOverload` on the UIKit/AppKit builders in
// `expectSnapshot.swift`: without it a builder body ties with the platform overloads that
// share its argument labels, and every multi-statement cell here fails with "Ambiguous use of
// '__expectSnapshot(…)'" inside the expansion buffer.
//
// `asyncExplicitReturnOptsOutOfTheBuilder` guards the other direction: an explicit `return`
// opts a closure out of the result-builder transform entirely (SE-0289), which is what keeps
// the documented `{ await …; return Text(…) }` pattern compiling.
//
// Compiled, never rendered: this suite is disabled and owns no reference artifacts, so it
// builds on macOS and iOS alike.
import SnapshotTestingMacros
import SwiftUI
import Testing

@Suite(.disabled("Compile-only fixture for @ViewBuilder body shapes"))
struct ExpectSnapshotViewBuilderShapesFixture {
  @Test
  func siblingViews() {
    #expectSnapshot(named: "unused") {
      Text("first")
      Text("second")
    }
  }

  @Test
  func ifElseBody() {
    #expectSnapshot(named: "unused") {
      if showsDetail() {
        Text("detail")
      }
      else {
        Image(systemName: "star")
      }
    }
  }

  @Test
  func bareIfBody() {
    #expectSnapshot(named: "unused") {
      if showsDetail() {
        Text("detail")
      }
    }
  }

  @Test
  func switchBody() {
    #expectSnapshot(named: "unused") {
      switch state() {
        case .empty:
          Text("empty")
        case .populated:
          Image(systemName: "star")
      }
    }
  }

  @Test
  func forEachBody() {
    #expectSnapshot(named: "unused") {
      Text("header")
      ForEach(0..<3, id: \.self) { index in
        Text("row \(index)")
      }
    }
  }

  @Test
  func singleExpressionBody() {
    #expectSnapshot(named: "unused") {
      Text("single")
    }
  }

  @Test
  func argumentSiblingViews() {
    #expectSnapshot(argument: "guest", named: "unused") { state in
      Text(state)
      Text("second")
    }
  }

  @Test
  func configurationIfElseBody() {
    #expectSnapshot(Self.configuration, named: "unused") { state in
      if showsDetail() {
        Text(state)
      }
      else {
        Image(systemName: "star")
      }
    }
  }

  @Test
  func tuple2ConfigurationSiblingViews() {
    #expectSnapshot(Self.tuple2Configuration, named: "unused") { state, count in
      Text(state)
      Text("\(count)")
    }
  }

  @Test
  func tuple3ConfigurationSwitchBody() {
    #expectSnapshot(Self.tuple3Configuration, named: "unused") { state, count, flag in
      switch self.state() {
        case .empty:
          Text(state)
        case .populated:
          Text("\(count)\(flag)")
      }
    }
  }

  /// The documented async pattern: an explicit `return` opts the closure out of the builder
  /// transform, so adding `@ViewBuilder` to the synchronous sibling must not break it.
  @Test
  func asyncExplicitReturnOptsOutOfTheBuilder() async {
    await #expectSnapshot(named: "unused") {
      await Task.yield()
      return Text("explicit return")
    }
  }

  @Test
  func throwingSiblingViews() throws {
    try #expectSnapshot(named: "unused") {
      Text(try throwingTitle())
      Text("second")
    }
  }

  @Test
  func asyncSiblingViews() async {
    await #expectSnapshot(named: "unused") {
      Text(await asyncTitle())
      Text("second")
    }
  }

  @Test
  func asyncThrowingIfElseBody() async throws {
    try await #expectSnapshot(named: "unused") {
      if showsDetail() {
        Text(try await title())
      }
      else {
        Image(systemName: "star")
      }
    }
  }

  @Test
  func argumentAsyncThrowingSiblingViews() async throws {
    try await #expectSnapshot(argument: "guest", named: "unused") { state in
      Text(try await title())
      Text(state)
    }
  }

  @Test
  func configurationAsyncForEachBody() async {
    await #expectSnapshot(Self.configuration, named: "unused") { state in
      Text(await asyncTitle())
      ForEach(0..<2, id: \.self) { index in
        Text("\(state)\(index)")
      }
    }
  }

  @Test
  func tuple3ConfigurationThrowingBareIfBody() throws {
    try #expectSnapshot(Self.tuple3Configuration, named: "unused") { state, count, flag in
      Text(try throwingTitle())
      if flag {
        Text("\(state)\(count)")
      }
    }
  }

  private static let configuration = SnapshotConfiguration(name: "probe", value: "guest")
  private static let tuple2Configuration = SnapshotConfiguration(name: "probe", value: ("guest", 1))
  private static let tuple3Configuration = SnapshotConfiguration(
    name: "probe",
    value: ("guest", 1, true)
  )
}

private enum ViewBuilderShapeState {
  case empty
  case populated
}

extension ExpectSnapshotViewBuilderShapesFixture {
  fileprivate func showsDetail() -> Bool {
    true
  }

  fileprivate func state() -> ViewBuilderShapeState {
    .populated
  }

  fileprivate func title() async throws -> String {
    await Task.yield()
    return "async throwing title"
  }

  fileprivate func throwingTitle() throws -> String {
    "throwing title"
  }

  fileprivate func asyncTitle() async -> String {
    await Task.yield()
    return "async title"
  }
}
