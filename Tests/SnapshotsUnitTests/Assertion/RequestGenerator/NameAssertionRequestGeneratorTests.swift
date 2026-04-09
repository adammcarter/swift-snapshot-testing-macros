#if os(macOS)
import AppKit
import CoreGraphics
import Testing

@testable import SnapshotTestingMacros

@MainActor
@Suite
struct NameAssertionRequestGeneratorTests {
  @Test(arguments: themeCases)
  func `builds test name from context name size and theme`(
    theme: ThemeSnapshotTrait.Theme,
    expectedThemeName: String
  ) async throws {
    let request = try await makeRequest(
      contextName: "base",
      sizeTestName: "test_name_description_1",
      theme: snapshotTheme(from: theme)
    )

    #expect(request.testName == "base_test_name_description_1_\(expectedThemeName)")
    #expect(request.snapshotting.pathExtension == "txt")
  }

  @Test(arguments: themeCases)
  func `prefixes test name with configuration when present`(
    theme: ThemeSnapshotTrait.Theme,
    expectedThemeName: String
  ) async throws {
    let request = try await makeRequest(
      contextName: "base",
      configurationName: "Name-1",
      sizeTestName: "test_name_description_1",
      theme: snapshotTheme(from: theme)
    )

    #expect(request.testName == "Name-1_base_test_name_description_1_\(expectedThemeName)")
  }

  @Test
  func `passes metadata through to final request`() async throws {
    let request = try await makeRequest(
      contextName: "base",
      sizeTestName: "test_name_description_1",
      theme: .light
    )

    AssertionRequestGeneratorTestSupport.assertCommonMetadata(request)
  }

  private func snapshotTheme(from theme: ThemeSnapshotTrait.Theme) -> SnapshotTheme {
    switch theme {
      case .light, .all: .light
      case .dark: .dark
    }
  }

  private func makeRequest(
    contextName: String,
    configurationName: String? = nil,
    sizeTestName: String,
    theme: SnapshotTheme
  ) async throws -> AssertionRequest<String> {
    let context = AssertionRequestGeneratorTestSupport.makeContext(
      name: contextName,
      configurationName: configurationName,
      traitConfiguration: .init(
        sizes: [],
        theme: .light,
        strategy: .recursiveDescription
      )
    )

    let requests = try await NameAssertionRequestGenerator(
      context: context,
      traitSize: AssertionRequestGeneratorTestSupport.makeTraitSize(
        testNameDescription: sizeTestName
      ),
      size: .init(width: 120, height: 80),
      theme: theme,
      displayScale: 2.0
    )
    .generateRequests()

    #expect(requests.count == 1)

    return try #require(requests.first as? AssertionRequest<String>)
  }

  nonisolated static let themeCases: [(theme: ThemeSnapshotTrait.Theme, expectedThemeName: String)] = [
    (.light, "light"),
    (.dark, "dark"),
  ]
}
#endif
