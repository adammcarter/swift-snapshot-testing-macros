import SwiftUI
import Testing

@testable import SnapshotTestingMacros

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
        throw ClosureFailure.sentinel
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
        await Task.yield()
        throw ClosureFailure.sentinel
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
        throw ClosureFailure.sentinel
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
        await Task.yield()
        throw ClosureFailure.sentinel
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
        throw ClosureFailure.sentinel
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
        await Task.yield()
        throw ClosureFailure.sentinel
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
    var sawContext = false

    do {
      try #expectSnapshot(argument: "guest", named: "unused") { (_: String) throws -> Text in
        sawContext = TaskLocalSnapshotExecutionContext.current != nil
        throw ClosureFailure.sentinel
      }

      Issue.record("Expected sentinel error")
    }
    catch ClosureFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }

    #expect(sawContext)
  }

  @Test
  func asyncThrowingTuple2ConfigurationHelperExecutesInsideSnapshotExecutionContextAndForwardsValuesInOrder() async {
    let configuration = SnapshotConfiguration(name: nil, value: ("first", "second"))
    var sawContext = false
    var received: (String, String)?

    do {
      try await #expectSnapshot(configuration, named: "unused") { first, second async throws -> Text in
        await Task.yield()
        sawContext = TaskLocalSnapshotExecutionContext.current != nil
        received = (first, second)
        throw ClosureFailure.sentinel
      }

      Issue.record("Expected sentinel error")
    }
    catch ClosureFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }

    #expect(sawContext)
    #expect(received?.0 == "first")
    #expect(received?.1 == "second")
  }

  @Test
  func asyncThrowingTuple3ConfigurationHelperExecutesInsideSnapshotExecutionContextAndForwardsValuesInOrder() async {
    let configuration = SnapshotConfiguration(name: nil, value: ("first", "second", "third"))
    var sawContext = false
    // swiftlint:disable:next large_tuple
    var received: (String, String, String)?

    do {
      try await #expectSnapshot(configuration, named: "unused") { first, second, third async throws -> Text in
        await Task.yield()
        sawContext = TaskLocalSnapshotExecutionContext.current != nil
        received = (first, second, third)
        throw ClosureFailure.sentinel
      }

      Issue.record("Expected sentinel error")
    }
    catch ClosureFailure.sentinel {
    }
    catch {
      Issue.record("Expected sentinel error, got: \(error.localizedDescription)")
    }

    #expect(sawContext)
    #expect(received?.0 == "first")
    #expect(received?.1 == "second")
    #expect(received?.2 == "third")
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

  private enum SwiftUISnapshotFailure: Error {
    case sentinel
  }

  private func throwingSwiftUIView() throws -> Text {
    throw SwiftUISnapshotFailure.sentinel
  }
}
