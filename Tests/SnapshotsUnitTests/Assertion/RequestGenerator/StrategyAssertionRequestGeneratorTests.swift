#if os(macOS)
import AppKit
import CoreGraphics
import Testing

@testable import SnapshotTestingMacros

@MainActor
@Suite
struct StrategyAssertionRequestGeneratorTests {
  @Test(arguments: configuredStrategyCases)
  func returnsRequestForConfiguredStrategy(entry: ConfiguredStrategyCase) async throws {
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
  func ignoresTaskLocalStrategyWhenConfiguredStrategyIsSet() async throws {
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
  func recursiveDescriptionLaysOutAtTheRequestSize() async throws {
    let context = AssertionRequestGeneratorTestSupport.makeContext(
      traitConfiguration: .init(
        sizes: [],
        theme: .light,
        strategy: .recursiveDescription
      )
    )

    let maybeRequest = try await StrategyAssertionRequestGenerator(
      context: context,
      size: .init(width: 123, height: 47),
      theme: .light,
      displayScale: 2.0,
      testName: "name"
    )
    .generateRequests().first

    let request = try #require(maybeRequest as? AssertionRequest<String>)
    let dump = render(request)

    // The support view is created at 200x200; the dump must reflect the request size instead.
    #expect(dump.contains("f=(0,0,123,47)"))
    #expect(dump.contains("f=(0,0,200,200)") == false)
  }

  @Test
  func recursiveDescriptionAppliesThemeAppearance() async throws {
    let context = AssertionRequestGeneratorTestSupport.makeContext(
      traitConfiguration: .init(
        sizes: [],
        theme: .all,
        strategy: .recursiveDescription
      )
    )

    let maybeRequest = try await StrategyAssertionRequestGenerator(
      context: context,
      size: .init(width: 100, height: 100),
      theme: .dark,
      displayScale: 2.0,
      testName: "name"
    )
    .generateRequests().first

    let request = try #require(maybeRequest as? AssertionRequest<String>)
    _ = render(request)

    #expect(request.view.view.appearance?.name == .darkAqua)
  }

  private func render(_ request: AssertionRequest<String>) -> String {
    var dump = ""
    request.snapshotting.snapshot(request.view).run { dump = $0 }
    return dump
  }

  struct ConfiguredStrategyCase: Sendable {
    let contextStrategy: StrategySnapshotTrait.Strategy
  }

  nonisolated static let configuredStrategyCases: [ConfiguredStrategyCase] = [
    .init(contextStrategy: .image),
    .init(contextStrategy: .recursiveDescription),
  ]

}
#endif
