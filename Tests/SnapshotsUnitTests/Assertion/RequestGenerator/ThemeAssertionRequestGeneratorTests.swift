#if os(macOS)
import CoreGraphics
import Testing

@testable import SnapshotTestingMacros

@MainActor
@Suite
struct ThemeAssertionRequestGeneratorTests {
  @Test(arguments: configuredThemeCases)
  func returnsRequestsForConfiguredTheme(entry: ConfiguredThemeCase) async throws {
    let requests = try await generateRequests(
      contextTheme: entry.contextTheme,
      taskLocalTheme: nil
    )

    #expect(requests.count == entry.expectedTestNames.count)
    #expect(Set(requests.map(\.testName)) == entry.expectedTestNames)
    requests.forEach(AssertionRequestGeneratorTestSupport.assertCommonMetadata(_:))
  }

  @Test
  func ignoresTaskLocalThemeWhenConfiguredThemeIsSet() async throws {
    let requests = try await generateRequests(
      contextTheme: .all,
      taskLocalTheme: .dark
    )

    #expect(requests.count == 2)
    #expect(
      Set(requests.map(\.testName)) == [
        "base_test_name_description_1_light",
        "base_test_name_description_1_dark",
      ]
    )
    requests.forEach(AssertionRequestGeneratorTestSupport.assertCommonMetadata(_:))
  }

  private func generateRequests(
    contextTheme: ThemeSnapshotTrait.Theme,
    taskLocalTheme: ThemeSnapshotTrait.Theme?
  ) async throws -> [AssertionRequest<String>] {
    let context = AssertionRequestGeneratorTestSupport.makeContext(
      traitConfiguration: .init(
        sizes: [],
        theme: contextTheme,
        strategy: .recursiveDescription
      )
    )

    func makeRequests() async throws -> [AssertionRequest<String>] {
      try await ThemeAssertionRequestGenerator(
        context: context,
        traitSize: AssertionRequestGeneratorTestSupport.makeTraitSize(),
        size: .init(width: 120, height: 80)
      )
      .generateRequests().map { try #require($0 as? AssertionRequest<String>) }
    }

    guard let taskLocalTheme else {
      return try await makeRequests()
    }

    return try await ThemeSnapshotTrait.$current.withValue(taskLocalTheme) {
      try await makeRequests()
    }
  }

  struct ConfiguredThemeCase: Sendable {
    let contextTheme: ThemeSnapshotTrait.Theme
    let expectedTestNames: Set<String>
  }

  nonisolated static let configuredThemeCases: [ConfiguredThemeCase] = [
    .init(
      contextTheme: .all,
      expectedTestNames: [
        "base_test_name_description_1_light",
        "base_test_name_description_1_dark",
      ]
    ),
    .init(
      contextTheme: .light,
      expectedTestNames: [
        "base_test_name_description_1_light"
      ]
    ),
    .init(
      contextTheme: .dark,
      expectedTestNames: [
        "base_test_name_description_1_dark"
      ]
    ),
  ]
}
#endif
