import Foundation
import SwiftUI
import Testing

@testable import SnapshotTestingMacros

/// Records what a `#expectSnapshot` builder observed from inside the main-actor hop.
///
/// Every SwiftUI and platform builder is `@MainActor`, and a main-actor-isolated closure is
/// `Sendable`, so a test cannot simply capture a local `var` in one. The hop is an exclusive
/// hand-off — the builder runs once while the caller is blocked or suspended — but that is not
/// something the compiler can prove, hence `@unchecked` plus the lock.
final class BuilderObservationBox<Value>: @unchecked Sendable {
  private let lock = NSLock()
  private var storedValue: Value

  init(_ value: Value) {
    storedValue = value
  }

  var value: Value {
    lock.withLock { storedValue }
  }

  func record(_ value: Value) {
    lock.withLock { storedValue = value }
  }
}

struct ExpectSnapshotAdapterTests {
  private enum ClosureFailure: Error {
    case sentinel
  }

  @Test
  func displayNamePrefersExplicitName() {
    let displayName = ExpectSnapshotAdapter.displayName(named: "custom-name", baseName: "myTest")

    #expect(displayName == "custom-name")
  }

  @Test
  func throwingClosureHelperRethrowsClosureErrors() {
    do {
      try __expectSnapshot(named: "unused") { () throws -> Text in
        try Self.failingView()
      }

      Issue.record("Expected sentinel error")
    }
    catch ClosureFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func throwingDirectSwiftUIViewHelperCompilesAndRethrowsValueErrors() {
    do {
      try #expectSnapshot(try throwingSwiftUIView(), named: "unused")
      Issue.record("Expected sentinel error")
    }
    catch SwiftUISnapshotFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func parenthesizedThrowingDirectSwiftUIViewHelperCompilesAndRethrowsValueErrors() {
    do {
      try #expectSnapshot((try throwingSwiftUIView()), named: "unused")
      Issue.record("Expected sentinel error")
    }
    catch SwiftUISnapshotFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func asyncThrowingClosureHelperRethrowsClosureErrors() async {
    do {
      try await __expectSnapshot(named: "unused") { () async throws -> Text in
        try await Self.failingViewAfterSuspension()
      }

      Issue.record("Expected sentinel error")
    }
    catch ClosureFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func throwingArgumentHelperRethrowsClosureErrors() {
    do {
      try #expectSnapshot(argument: "guest", named: "unused") { (_: String) throws -> Text in
        try Self.failingView()
      }

      Issue.record("Expected sentinel error")
    }
    catch ClosureFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func asyncThrowingArgumentHelperRethrowsClosureErrors() async {
    do {
      try await #expectSnapshot(argument: "guest", named: "unused") { (_: String) async throws -> Text in
        try await Self.failingViewAfterSuspension()
      }

      Issue.record("Expected sentinel error")
    }
    catch ClosureFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func throwingConfigurationHelperRethrowsClosureErrors() {
    do {
      let configuration = SnapshotConfiguration(name: nil, value: "guest")

      try #expectSnapshot(configuration, named: "unused") { (_: String) throws -> Text in
        try Self.failingView()
      }

      Issue.record("Expected sentinel error")
    }
    catch ClosureFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func asyncThrowingConfigurationHelperRethrowsClosureErrors() async {
    do {
      let configuration = SnapshotConfiguration(name: nil, value: "guest")

      try await #expectSnapshot(configuration, named: "unused") { (_: String) async throws -> Text in
        try await Self.failingViewAfterSuspension()
      }

      Issue.record("Expected sentinel error")
    }
    catch ClosureFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test
  func throwingArgumentHelperExecutesInsideSnapshotExecutionContext() {
    let sawContext = BuilderObservationBox(false)

    do {
      try #expectSnapshot(argument: "guest", named: "unused") { (_: String) throws -> Text in
        sawContext.record(TaskLocalSnapshotExecutionContext.current != nil)

        return try Self.failingView()
      }

      Issue.record("Expected sentinel error")
    }
    catch ClosureFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }

    #expect(sawContext.value)
  }

  @Test
  func asyncThrowingTuple2ConfigurationHelperExecutesInsideSnapshotExecutionContextAndForwardsValuesInOrder() async {
    let configuration = SnapshotConfiguration(name: nil, value: ("first", "second"))
    let sawContext = BuilderObservationBox(false)
    let received = BuilderObservationBox<(String, String)?>(nil)

    do {
      try await #expectSnapshot(configuration, named: "unused") { first, second async throws -> Text in
        await Task.yield()
        sawContext.record(TaskLocalSnapshotExecutionContext.current != nil)
        received.record((first, second))

        return try Self.failingView()
      }

      Issue.record("Expected sentinel error")
    }
    catch ClosureFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }

    #expect(sawContext.value)
    #expect(received.value?.0 == "first")
    #expect(received.value?.1 == "second")
  }

  @Test
  func asyncThrowingTuple3ConfigurationHelperExecutesInsideSnapshotExecutionContextAndForwardsValuesInOrder() async {
    let configuration = SnapshotConfiguration(name: nil, value: ("first", "second", "third"))
    let sawContext = BuilderObservationBox(false)
    // swiftlint:disable:next large_tuple
    let received = BuilderObservationBox<(String, String, String)?>(nil)

    do {
      try await #expectSnapshot(configuration, named: "unused") { first, second, third async throws -> Text in
        await Task.yield()
        sawContext.record(TaskLocalSnapshotExecutionContext.current != nil)
        received.record((first, second, third))

        return try Self.failingView()
      }

      Issue.record("Expected sentinel error")
    }
    catch ClosureFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }

    #expect(sawContext.value)
    #expect(received.value?.0 == "first")
    #expect(received.value?.1 == "second")
    #expect(received.value?.2 == "third")
  }

  @Test
  func parameterHelpersExposeAsyncEffectSignatures() {
    let argumentAsync: (String) async -> Void = { argument in
      await #expectSnapshot(argument: argument, named: "unused") { argument in
        await Task.yield()
        return Text(argument)
      }
    }
    let configurationAsync: (SnapshotConfiguration<(String, String)>) async -> Void = { configuration in
      await #expectSnapshot(configuration, named: "unused") { first, second in
        await Task.yield()
        return Text(first + second)
      }
    }

    _ = argumentAsync
    _ = configurationAsync
    #expect(Bool(true))
  }

  /// A view factory that only ever throws.
  ///
  /// The SwiftUI builders are `@ViewBuilder`, and a builder body must be made of view
  /// expressions, declarations and control flow — a bare `throw` statement transforms to
  /// `EmptyView` and no longer satisfies the closure's declared result type. Routing the
  /// sentinel through a `Text`-typed factory keeps these rethrow characterizations expressed
  /// as ordinary builder bodies.
  private static func failingView() throws -> Text {
    throw ClosureFailure.sentinel
  }

  private static func failingViewAfterSuspension() async throws -> Text {
    await Task.yield()

    throw ClosureFailure.sentinel
  }

  private enum SwiftUISnapshotFailure: Error {
    case sentinel
  }

  private func throwingSwiftUIView() throws -> Text {
    throw SwiftUISnapshotFailure.sentinel
  }
}
