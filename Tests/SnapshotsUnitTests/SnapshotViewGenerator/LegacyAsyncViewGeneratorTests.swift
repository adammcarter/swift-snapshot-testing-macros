#if os(macOS)
import SwiftUI
import Testing

@testable import SnapshotTestingMacros

/// Regression tests for the async legacy codegen path.
///
/// Legacy `@SnapshotTest func makeView() async -> some View` (and suites whose first init is
/// async) expand to `makeValue: { await Suite().makeView() }`. Since the sync assertion
/// refactor, `SnapshotViewGenerator` only offered synchronous `makeValue` initialisers, so that
/// generated code no longer compiled. These tests construct the exact closure shapes the macro
/// emits and prove the async value is resolved once, before the synchronous pipeline runs.
@MainActor
@Suite
struct LegacyAsyncViewGeneratorTests {

  @Test
  func asyncSwiftUIMakeValueIsStoredForAsyncResolution() async throws {
    let generator = makeAsyncSwiftUIGenerator()

    let makeViewControllerAsync = try #require(generator.makeViewControllerAsync)
    let viewController = try await makeViewControllerAsync(())

    #expect(viewController.view != nil)
  }

  @Test
  func asyncThrowingSwiftUIMakeValueIsStoredForAsyncResolution() async throws {
    let generator = SnapshotViewGenerator<Void>(
      displayName: "async throws legacy",
      configuration: .none,
      makeValue: { try await Self.makeThrowingViewAsync() },
      fileID: "fileID",
      filePath: "filePath",
      line: 1,
      column: 1
    )

    let makeViewControllerAsync = try #require(generator.makeViewControllerAsync)
    let viewController = try await makeViewControllerAsync(())

    #expect(viewController.view != nil)
  }

  @Test
  func asyncPlatformViewMakeValueIsStoredForAsyncResolution() async throws {
    let generator = SnapshotViewGenerator<Void>(
      displayName: "async platform view",
      configuration: .none,
      makeValue: { await Self.makePlatformViewAsync() },
      fileID: "fileID",
      filePath: "filePath",
      line: 1,
      column: 1
    )

    let makeViewControllerAsync = try #require(generator.makeViewControllerAsync)
    let viewController = try await makeViewControllerAsync(())

    #expect(viewController.view != nil)
  }

  @Test
  func asyncViewControllerMakeValueIsStoredForAsyncResolution() async throws {
    let generator = SnapshotViewGenerator<Void>(
      displayName: "async view controller",
      configuration: .none,
      makeValue: { await Self.makeViewControllerAsync() },
      fileID: "fileID",
      filePath: "filePath",
      line: 1,
      column: 1
    )

    let makeViewControllerAsync = try #require(generator.makeViewControllerAsync)
    let viewController = try await makeViewControllerAsync(())

    #expect(viewController.view != nil)
  }

  @Test
  func asyncGeneratorResolvesToASyncGeneratorBeforeTheSyncPipeline() async throws {
    let generator = makeAsyncSwiftUIGenerator()

    let resolved = try await resolvedSyncViewGenerator(from: generator)
    let resolvedGenerator = try #require(resolved as? SnapshotViewGenerator<Void>)

    #expect(resolvedGenerator.displayName == "async legacy")
    #expect(resolvedGenerator.makeViewControllerAsync == nil)
    #expect(resolvedGenerator.line == 3)
    #expect(resolvedGenerator.column == 7)

    let viewController = try resolvedGenerator.makeViewController(())
    #expect(viewController.view != nil)
  }

  @Test
  func syncGeneratorPassesThroughResolutionUntouched() async throws {
    let generator = SnapshotViewGenerator<Void>(
      displayName: "sync legacy",
      configuration: .none,
      makeValue: { Text("sync") },
      fileID: "fileID",
      filePath: "filePath",
      line: 1,
      column: 1
    )

    #expect(generator.makeViewControllerAsync == nil)

    let resolved = try await resolvedSyncViewGenerator(from: generator)
    let resolvedGenerator = try #require(resolved as? SnapshotViewGenerator<Void>)

    #expect(resolvedGenerator.displayName == "sync legacy")
    let viewController = try resolvedGenerator.makeViewController(())
    #expect(viewController.view != nil)
  }

  @Test
  func unresolvedAsyncGeneratorThrowsFromTheSyncEntryPoint() {
    let generator = makeAsyncSwiftUIGenerator()

    #expect(throws: (any Error).self) {
      try generator.makeViewController(())
    }
  }

  private func makeAsyncSwiftUIGenerator() -> SnapshotViewGenerator<Void> {
    SnapshotViewGenerator<Void>(
      displayName: "async legacy",
      configuration: .none,
      makeValue: { await Self.makeViewAsync() },
      fileID: "fileID",
      filePath: "filePath",
      line: 3,
      column: 7
    )
  }

  private static func makeViewAsync() async -> some View {
    Text("async")
  }

  private static func makeThrowingViewAsync() async throws -> some View {
    Text("async throws")
  }

  private static func makePlatformViewAsync() async -> SnapshotView {
    SnapshotView(frame: .init(x: 0, y: 0, width: 10, height: 10))
  }

  private static func makeViewControllerAsync() async -> SnapshotViewController {
    let controller = SnapshotViewController()
    controller.view = SnapshotView(frame: .init(x: 0, y: 0, width: 10, height: 10))
    return controller
  }
}
#endif
