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

  /// The headline of the direct-value effect matrix: `try await` on a direct value used to be
  /// unrepresentable, because the expansion put the expression in a sync `@autoclosure` and the
  /// compiler reported "'async' call in an autoclosure that does not support concurrency" at
  /// line 2 of a macro expansion buffer the author cannot open.
  @Test
  func asyncThrowingDirectSwiftUIValueRethrowsValueErrors() async {
    do {
      try await #expectSnapshot(try await throwingSwiftUIViewAfterSuspension(), named: "unused")
      Issue.record("Expected sentinel error")
    }
    catch SwiftUISnapshotFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  /// A `try` nested inside a larger expression is still a throwing direct value. The previous
  /// expansion only recognized a `try` at the very root of the expression, so this shape failed
  /// with "Call can throw, but it is executed in a non-throwing autoclosure".
  @Test
  func nestedThrowingDirectSwiftUIValueRethrowsValueErrors() {
    do {
      try #expectSnapshot(DirectValueWrapper(inner: try throwingSwiftUIView()), named: "unused")
      Issue.record("Expected sentinel error")
    }
    catch SwiftUISnapshotFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }
  }

  @Test(.record(.never))
  func awaitingDirectSwiftUIValueIsEvaluatedInsideTheSnapshotHop() async {
    let sawContext = BuilderObservationBox(false)

    await withKnownIssue {
      await #expectSnapshot(await Self.suspendingView(recording: sawContext), named: "unused")
    } matching: { issue in
      issue.comments.contains { $0.rawValue.contains("No reference was found on disk") }
    }

    #expect(sawContext.value)
  }

  /// `try?` and `try!` handle the error inside the expression, so the assertion stays
  /// non-throwing and needs no `try` at the call site.
  @Test(.record(.never))
  func optionalTryDirectSwiftUIValueDoesNotRethrow() {
    withKnownIssue {
      #expectSnapshot(try? succeedingSwiftUIView(), named: "unused")
    } matching: { issue in
      issue.comments.contains { $0.rawValue.contains("No reference was found on disk") }
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

  private static func suspendingView(recording box: BuilderObservationBox<Bool>) async -> Text {
    await Task.yield()
    box.record(TaskLocalSnapshotExecutionContext.current != nil)

    return Text("suspended")
  }

  private enum SwiftUISnapshotFailure: Error {
    case sentinel
  }

  private func throwingSwiftUIView() throws -> Text {
    throw SwiftUISnapshotFailure.sentinel
  }

  /// A `throws`-declared factory that never actually throws, so `try?` produces a renderable
  /// value rather than `nil` — the point of the characterization is that the assertion stays
  /// non-throwing, not that an empty optional renders.
  private func succeedingSwiftUIView() throws -> Text {
    Text("optional")
  }

  private func throwingSwiftUIViewAfterSuspension() async throws -> Text {
    await Task.yield()

    throw SwiftUISnapshotFailure.sentinel
  }
}

/// Wraps a direct value so a `try` can sit somewhere other than the root of the expression.
private struct DirectValueWrapper: View {
  let inner: Text

  var body: some View {
    inner
  }
}
