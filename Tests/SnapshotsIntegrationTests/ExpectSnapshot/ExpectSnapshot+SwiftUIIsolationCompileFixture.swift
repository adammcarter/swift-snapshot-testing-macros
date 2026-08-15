// Compile-only regression fixtures for the SwiftUI builder family's isolation contract.
//
// Every SwiftUI builder is `@MainActor`, like its UIKit/AppKit counterpart, so the same call
// site has to compile from a `@MainActor` suite — the shape README recommends — *and* from a
// nonisolated one. Before the builders were isolated there was no isolation that satisfied
// all four effect cells: from a `@MainActor` suite the `async` and `async throws` forms were
// rejected ("sending value of non-Sendable type '() async -> Text' risks causing data
// races"), and from a nonisolated suite no form could reach main-actor state at all.
//
// Every cell therefore reads main-actor state *synchronously* inside the builder — that is
// the property the isolation buys, and a builder that regressed to nonisolated cannot compile
// it from either suite.
//
// These suites exist to be compiled, not to record or compare reference artifacts: they are
// disabled and own no references. That is also what lets them build on macOS and iOS alike,
// unlike the rendering suites that their iOS-recorded references gate to UIKit.
import SnapshotTestingMacros
import SwiftUI
import Testing

@MainActor
@Suite(.disabled("Compile-only fixture for SwiftUI builder isolation"))
struct SwiftUIIsolationMainActorFixture {
  @Test
  func directValue() {
    #expectSnapshot(Text(mainActorTitle()), named: "unused")
  }

  @Test
  func throwingDirectValue() throws {
    try #expectSnapshot(try throwingMainActorView(), named: "unused")
  }

  @Test
  func bareSync() {
    #expectSnapshot(named: "unused") { Text(mainActorTitle()) }
  }

  @Test
  func bareThrowing() throws {
    try #expectSnapshot(named: "unused") { Text(try throwingTitle()) }
  }

  @Test
  func bareAsync() async {
    await #expectSnapshot(named: "unused") {
      await Task.yield()
      return Text(mainActorTitle())
    }
  }

  @Test
  func bareAsyncThrowing() async throws {
    try await #expectSnapshot(named: "unused") {
      try await yieldThenSucceed()
      return Text(mainActorTitle())
    }
  }

  @Test
  func argumentSync() {
    #expectSnapshot(argument: "guest", named: "unused") { state in
      Text(mainActorTitle() + state)
    }
  }

  @Test
  func argumentThrowing() throws {
    try #expectSnapshot(argument: "guest", named: "unused") { state in
      Text(try throwingTitle() + state)
    }
  }

  @Test
  func argumentAsync() async {
    await #expectSnapshot(argument: "guest", named: "unused") { state in
      await Task.yield()
      return Text(mainActorTitle() + state)
    }
  }

  @Test
  func argumentAsyncThrowing() async throws {
    try await #expectSnapshot(argument: "guest", named: "unused") { state in
      try await yieldThenSucceed()
      return Text(mainActorTitle() + state)
    }
  }

  @Test
  func configurationSync() {
    #expectSnapshot(Self.configuration, named: "unused") { state in
      Text(mainActorTitle() + state)
    }
  }

  @Test
  func configurationThrowing() throws {
    try #expectSnapshot(Self.configuration, named: "unused") { state in
      Text(try throwingTitle() + state)
    }
  }

  @Test
  func configurationAsync() async {
    await #expectSnapshot(Self.configuration, named: "unused") { state in
      await Task.yield()
      return Text(mainActorTitle() + state)
    }
  }

  @Test
  func configurationAsyncThrowing() async throws {
    try await #expectSnapshot(Self.configuration, named: "unused") { state in
      try await yieldThenSucceed()
      return Text(mainActorTitle() + state)
    }
  }

  @Test
  func tuple2ConfigurationSync() {
    #expectSnapshot(Self.tuple2Configuration, named: "unused") { state, count in
      Text("\(mainActorTitle())\(state)\(count)")
    }
  }

  @Test
  func tuple2ConfigurationThrowing() throws {
    try #expectSnapshot(Self.tuple2Configuration, named: "unused") { state, count in
      Text("\(try throwingTitle())\(state)\(count)")
    }
  }

  @Test
  func tuple2ConfigurationAsync() async {
    await #expectSnapshot(Self.tuple2Configuration, named: "unused") { state, count in
      await Task.yield()
      return Text("\(mainActorTitle())\(state)\(count)")
    }
  }

  @Test
  func tuple2ConfigurationAsyncThrowing() async throws {
    try await #expectSnapshot(Self.tuple2Configuration, named: "unused") { state, count in
      try await yieldThenSucceed()
      return Text("\(mainActorTitle())\(state)\(count)")
    }
  }

  @Test
  func tuple3ConfigurationSync() {
    #expectSnapshot(Self.tuple3Configuration, named: "unused") { state, count, flag in
      Text("\(mainActorTitle())\(state)\(count)\(flag)")
    }
  }

  @Test
  func tuple3ConfigurationThrowing() throws {
    try #expectSnapshot(Self.tuple3Configuration, named: "unused") { state, count, flag in
      Text("\(try throwingTitle())\(state)\(count)\(flag)")
    }
  }

  @Test
  func tuple3ConfigurationAsync() async {
    await #expectSnapshot(Self.tuple3Configuration, named: "unused") { state, count, flag in
      await Task.yield()
      return Text("\(mainActorTitle())\(state)\(count)\(flag)")
    }
  }

  @Test
  func tuple3ConfigurationAsyncThrowing() async throws {
    try await #expectSnapshot(Self.tuple3Configuration, named: "unused") { state, count, flag in
      try await yieldThenSucceed()
      return Text("\(mainActorTitle())\(state)\(count)\(flag)")
    }
  }

  private static let configuration = SnapshotConfiguration(name: "probe", value: "guest")
  private static let tuple2Configuration = SnapshotConfiguration(name: "probe", value: ("guest", 1))
  private static let tuple3Configuration = SnapshotConfiguration(
    name: "probe",
    value: ("guest", 1, true)
  )
}

@Suite(.disabled("Compile-only fixture for SwiftUI builder isolation"))
struct SwiftUIIsolationNonisolatedFixture {
  @Test
  func directValue() {
    #expectSnapshot(Text(mainActorTitle()), named: "unused")
  }

  @Test
  func throwingDirectValue() throws {
    try #expectSnapshot(try throwingMainActorView(), named: "unused")
  }

  @Test
  func bareSync() {
    #expectSnapshot(named: "unused") { Text(mainActorTitle()) }
  }

  @Test
  func bareThrowing() throws {
    try #expectSnapshot(named: "unused") { Text(try throwingTitle()) }
  }

  @Test
  func bareAsync() async {
    await #expectSnapshot(named: "unused") {
      await Task.yield()
      return Text(mainActorTitle())
    }
  }

  @Test
  func bareAsyncThrowing() async throws {
    try await #expectSnapshot(named: "unused") {
      try await yieldThenSucceed()
      return Text(mainActorTitle())
    }
  }

  @Test
  func argumentSync() {
    #expectSnapshot(argument: "guest", named: "unused") { state in
      Text(mainActorTitle() + state)
    }
  }

  @Test
  func argumentThrowing() throws {
    try #expectSnapshot(argument: "guest", named: "unused") { state in
      Text(try throwingTitle() + state)
    }
  }

  @Test
  func argumentAsync() async {
    await #expectSnapshot(argument: "guest", named: "unused") { state in
      await Task.yield()
      return Text(mainActorTitle() + state)
    }
  }

  @Test
  func argumentAsyncThrowing() async throws {
    try await #expectSnapshot(argument: "guest", named: "unused") { state in
      try await yieldThenSucceed()
      return Text(mainActorTitle() + state)
    }
  }

  @Test
  func configurationSync() {
    #expectSnapshot(Self.configuration, named: "unused") { state in
      Text(mainActorTitle() + state)
    }
  }

  @Test
  func configurationThrowing() throws {
    try #expectSnapshot(Self.configuration, named: "unused") { state in
      Text(try throwingTitle() + state)
    }
  }

  @Test
  func configurationAsync() async {
    await #expectSnapshot(Self.configuration, named: "unused") { state in
      await Task.yield()
      return Text(mainActorTitle() + state)
    }
  }

  @Test
  func configurationAsyncThrowing() async throws {
    try await #expectSnapshot(Self.configuration, named: "unused") { state in
      try await yieldThenSucceed()
      return Text(mainActorTitle() + state)
    }
  }

  @Test
  func tuple2ConfigurationSync() {
    #expectSnapshot(Self.tuple2Configuration, named: "unused") { state, count in
      Text("\(mainActorTitle())\(state)\(count)")
    }
  }

  @Test
  func tuple2ConfigurationThrowing() throws {
    try #expectSnapshot(Self.tuple2Configuration, named: "unused") { state, count in
      Text("\(try throwingTitle())\(state)\(count)")
    }
  }

  @Test
  func tuple2ConfigurationAsync() async {
    await #expectSnapshot(Self.tuple2Configuration, named: "unused") { state, count in
      await Task.yield()
      return Text("\(mainActorTitle())\(state)\(count)")
    }
  }

  @Test
  func tuple2ConfigurationAsyncThrowing() async throws {
    try await #expectSnapshot(Self.tuple2Configuration, named: "unused") { state, count in
      try await yieldThenSucceed()
      return Text("\(mainActorTitle())\(state)\(count)")
    }
  }

  @Test
  func tuple3ConfigurationSync() {
    #expectSnapshot(Self.tuple3Configuration, named: "unused") { state, count, flag in
      Text("\(mainActorTitle())\(state)\(count)\(flag)")
    }
  }

  @Test
  func tuple3ConfigurationThrowing() throws {
    try #expectSnapshot(Self.tuple3Configuration, named: "unused") { state, count, flag in
      Text("\(try throwingTitle())\(state)\(count)\(flag)")
    }
  }

  @Test
  func tuple3ConfigurationAsync() async {
    await #expectSnapshot(Self.tuple3Configuration, named: "unused") { state, count, flag in
      await Task.yield()
      return Text("\(mainActorTitle())\(state)\(count)\(flag)")
    }
  }

  @Test
  func tuple3ConfigurationAsyncThrowing() async throws {
    try await #expectSnapshot(Self.tuple3Configuration, named: "unused") { state, count, flag in
      try await yieldThenSucceed()
      return Text("\(mainActorTitle())\(state)\(count)\(flag)")
    }
  }

  private static let configuration = SnapshotConfiguration(name: "probe", value: "guest")
  private static let tuple2Configuration = SnapshotConfiguration(name: "probe", value: ("guest", 1))
  private static let tuple3Configuration = SnapshotConfiguration(
    name: "probe",
    value: ("guest", 1, true)
  )
}

private enum SwiftUIIsolationFixtureFailure: Error {
  case sentinel
}

/// The main-actor state every cell reads synchronously inside its builder, so a builder that
/// is not main-actor isolated cannot compile this file.
@MainActor
private func mainActorTitle() -> String {
  "main-actor title"
}

@MainActor
private func throwingMainActorView() throws -> Text {
  Text(mainActorTitle())
}

@MainActor
private func throwingTitle() throws -> String {
  mainActorTitle()
}

/// Nonisolated on purpose: the suspension must not be what carries the builder onto the main
/// actor — the builder's own isolation has to.
private func yieldThenSucceed() async throws {
  await Task.yield()

  guard Bool(true) else {
    throw SwiftUIIsolationFixtureFailure.sentinel
  }
}
