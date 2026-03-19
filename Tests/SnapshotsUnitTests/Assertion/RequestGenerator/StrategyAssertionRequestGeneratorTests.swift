#if os(macOS)
import AppKit
import CoreGraphics
import Testing

@testable import SnapshotTestingMacros

@MainActor
@Suite
struct StrategyAssertionRequestGeneratorTests {
  @Test(arguments: configuredStrategyCases)
  func `returns request for configured strategy`(entry: ConfiguredStrategyCase) async throws {
    let context = AssertionRequestGeneratorTestSupport.makeContext(
      traitConfiguration: .init(
        sizes: [],
        theme: .light,
        strategy: entry.contextStrategy
      )
    )

    let maybeRequest = try await StrategyAssertionRequestGenerator(
      context: context,
      size: .init(width: 100, height: 100),
      theme: .light,
      displayScale: 2.0,
      testName: "name"
    )
    .generateRequests().first

    let request = try #require(maybeRequest)

    #expect(request.testName == "name")
    AssertionRequestGeneratorTestSupport.assertCommonMetadata(request)

    switch entry.contextStrategy {
      case .image:
        let imageRequest = try #require(request as? AssertionRequest<NSImage>)
        #expect(imageRequest.snapshotting.pathExtension == "png")
      case .recursiveDescription:
        let recursiveRequest = try #require(request as? AssertionRequest<String>)
        #expect(recursiveRequest.snapshotting.pathExtension == "txt")
    }
  }

  @Test
  func `ignores task local strategy when configured strategy is set`() async throws {
    let context = AssertionRequestGeneratorTestSupport.makeContext(
      traitConfiguration: .init(
        sizes: [],
        theme: .light,
        strategy: .image
      )
    )

    let maybeRequest = try await StrategySnapshotTrait.$current.withValue(.recursiveDescription) {
      try await StrategyAssertionRequestGenerator(
        context: context,
        size: .init(width: 100, height: 100),
        theme: .light,
        displayScale: 2.0,
        testName: "name"
      )
      .generateRequests().first
    }

    let request = try #require(maybeRequest)
    let imageRequest = try #require(request as? AssertionRequest<NSImage>)

    #expect(request.testName == "name")
    AssertionRequestGeneratorTestSupport.assertCommonMetadata(request)
    #expect(imageRequest.snapshotting.pathExtension == "png")
  }

  @Test
  func `appkit image strategy still produces png snapshotting`() async throws {
    let imageRequest = try await makeImageRequest(displayScale: 3.0)

    #expect(imageRequest.snapshotting.pathExtension == "png")
  }

  struct ConfiguredStrategyCase: Sendable {
    let contextStrategy: StrategySnapshotTrait.Strategy
  }

  nonisolated static let configuredStrategyCases: [ConfiguredStrategyCase] = [
    .init(contextStrategy: .image),
    .init(contextStrategy: .recursiveDescription),
  ]

  private func makeImageRequest(
    displayScale: Double
  ) async throws -> AssertionRequest<NSImage> {
    let context = AssertionRequestGeneratorTestSupport.makeContext(
      traitConfiguration: .init(
        sizes: [],
        theme: .light,
        strategy: .image
      )
    )

    let maybeRequest = try await StrategyAssertionRequestGenerator(
      context: context,
      size: .init(width: 100, height: 100),
      theme: .dark,
      displayScale: displayScale,
      testName: "name"
    )
    .generateRequests().first

    return try #require(maybeRequest as? AssertionRequest<NSImage>)
  }

}
#endif
