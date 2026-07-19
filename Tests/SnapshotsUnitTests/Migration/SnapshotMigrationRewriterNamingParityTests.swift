#if os(macOS)
import AppKit
import Foundation
import Testing

@testable import SnapshotMigrationSupport
@testable import SnapshotTestingMacros

/// Regression coverage for parameterised migration naming parity.
///
/// Legacy parameterised `@SnapshotTest` artifacts live at
/// `__Snapshots__/<TestFile>/<display>/<case>_<display>_<size>_<theme>.<n>.<ext>` — the exact
/// layout the native `configuration:` pipeline produces on its own. The rewriter must therefore
/// pass the legacy display name through `named:` untouched (no slash composition) and hand the
/// case naming to the configuration machinery, so migrated tests keep matching the checked-in
/// legacy references byte for byte.
@Suite
struct RewriterNamingParityTests {
  // MARK: - Rewritten source shapes

  @Test
  func rewritesCheckedInLegacyFixtureToConfigurationMachineryCalls() throws {
    let fixtureSource = try String(contentsOfFile: Self.legacyFixturePath, encoding: .utf8)

    let result = try SnapshotMigrationRewriter().rewrite(source: fixtureSource)

    #expect(
      result.output.contains(
        #"let snapshotConfiguration = SnapshotConfiguration(name: "\(value)", value: value)"#
      )
    )
    #expect(
      result.output.contains(
        #"#expectSnapshot(snapshotConfiguration, named: "Legacy configuration values test") {"#
      )
    )
    #expect(!result.output.contains(#"+ "/" +"#))
    #expect(result.reasons.isEmpty)
  }

  @Test
  func rewritesConfigurationValuesWithoutDisplayNameUsingFunctionNameFallback() throws {
    let input = """
      @SnapshotTest(configurationValues: [1, 2])
      func configurationValues(value: Int) -> some View {
        Text("value: \\(value)")
      }
      """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(
      result.output.contains(
        #"let snapshotConfiguration = SnapshotConfiguration(name: "\(value)", value: value)"#
      )
    )
    #expect(
      result.output.contains(
        #"#expectSnapshot(snapshotConfiguration, named: "configurationValues") {"#
      )
    )
    #expect(!result.output.contains(#"+ "/" +"#))
    #expect(result.reasons.isEmpty)
  }

  @Test
  func rewritesConfigurationsToPassTheConfigurationThroughToTheAssertion() throws {
    let input = """
      @SnapshotTest("Cards", configurations: [
        .init(name: "compact", value: 1),
        .init(name: "expanded", value: 2),
      ])
      func cards(state: Int) -> some View {
        CardView(state: state)
      }
      """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(
      result.output.contains(
        #"#expectSnapshot(configuration, named: "Cards") {"#
      )
    )
    #expect(!result.output.contains(#"+ "/" +"#))
    #expect(result.reasons.isEmpty)
  }

  @Test
  func parameterizedDisplayNameFallsBackToSuiteDisplayNameBeforeFunctionName() throws {
    let input = """
      @SnapshotSuite("Suite Cards")
      struct CardSuite {
        @SnapshotTest(configurations: [.init(name: "compact", value: 1)])
        func cards(state: Int) -> some View {
          CardView(state: state)
        }
      }
      """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(
      result.output.contains(
        #"#expectSnapshot(configuration, named: "Suite Cards") {"#
      )
    )
    #expect(result.reasons.isEmpty)
  }

  // MARK: - Native pipeline path parity with the checked-in legacy artifacts

  @MainActor
  @Test
  func migratedConfigurationValuesResolveTheCheckedInLegacyArtifactPaths() throws {
    // The rewritten fixture executes, per case value:
    //   SnapshotConfiguration(name: "\(value)", value: value)
    //   #expectSnapshot(snapshotConfiguration, named: "Legacy configuration values test") { ... }
    for value in [1, 2] {
      let artifact = try nativeArtifactPath(
        displayName: "Legacy configuration values test",
        configuration: SnapshotConfiguration(name: "\(value)", value: value)
      )

      let expectedRelativePath =
        "Tests/SnapshotsIntegrationTests/SnapshotTest/__Snapshots__/LegacySnapshotTestMigration/"
        + "Legacy-configuration-values-test/"
        + "\(value)_Legacy-configuration-values-test_min-size_light.1.txt"

      #expect(artifact.repoRelativePath == expectedRelativePath)

      let checkedInArtifactPath = Self.repositoryRootPath + "/" + expectedRelativePath
      #expect(
        FileManager.default.fileExists(atPath: checkedInArtifactPath),
        "Expected the computed path to point at the checked-in legacy artifact: \(checkedInArtifactPath)"
      )
    }
  }

  @MainActor
  @Test
  func migratedConfigurationValuesWithoutDisplayNameResolveFunctionNameScopedPaths() throws {
    let artifact = try nativeArtifactPath(
      displayName: "configurationValues",
      configuration: SnapshotConfiguration(name: "\(1)", value: 1)
    )

    #expect(
      artifact.repoRelativePath
        == "Tests/SnapshotsIntegrationTests/SnapshotTest/__Snapshots__/LegacySnapshotTestMigration/"
        + "configurationValues/1_configurationValues_min-size_light.1.txt"
    )
  }

  @MainActor
  @Test
  func migratedConfigurationsWithExplicitCaseNamesResolveLegacyScopedPaths() throws {
    let artifact = try nativeArtifactPath(
      displayName: "Cards",
      configuration: SnapshotConfiguration(name: "compact", value: 1)
    )

    #expect(
      artifact.repoRelativePath
        == "Tests/SnapshotsIntegrationTests/SnapshotTest/__Snapshots__/LegacySnapshotTestMigration/"
        + "Cards/compact_Cards_min-size_light.1.txt"
    )
  }

  // MARK: - Native pipeline driver

  private struct Artifact {
    /// Path relative to the repository root, e.g.
    /// `Tests/.../__Snapshots__/<TestFile>/<folder>/<file>.1.txt`.
    let repoRelativePath: String
  }

  /// Computes the artifact path the migrated code produces at runtime by driving the real
  /// naming pipeline: adapter configuration-name resolution, then
  /// `AssertionRequestGenerator` → … → `NameAssertionRequestGenerator`, then the final
  /// pointfree-style sanitisation of the test name.
  @MainActor
  private func nativeArtifactPath<Value: Sendable>(
    displayName: String,
    configuration: SnapshotConfiguration<Value>
  ) throws -> Artifact {
    let resolvedConfiguration = SnapshotConfiguration(
      name: ExpectSnapshotAdapter.configurationName(for: configuration),
      value: configuration.value
    )

    let viewGenerator = SnapshotViewGenerator<Value>(
      displayName: displayName,
      configuration: resolvedConfiguration,
      makeValue: { _ in
        let controller = SnapshotViewController()
        controller.view = SnapshotView(frame: .init(x: 0, y: 0, width: 200, height: 100))
        return controller
      },
      fileID: "SnapshotsIntegrationTests/LegacySnapshotTestMigration.swift",
      filePath: Self.fixtureFilePathLiteral,
      line: 1,
      column: 1
    )

    // The legacy fixture ran with default sizes (min-size) and `.theme(.light)`. Fixed lengths
    // keep layout deterministic; the size trait's `testNameDescription` is the only sizing
    // input to the naming pipeline.
    let minSize = SizesSnapshotTrait.Size(
      width: .fixed(200),
      height: .fixed(100),
      displayName: "size",
      debugDescription: "fixed 200x100",
      testNameDescription: "min-size"
    )

    let requests = try SizesSnapshotTrait.$current.withValue([minSize]) {
      try ThemeSnapshotTrait.$current.withValue(.light) {
        try StrategySnapshotTrait.$current.withValue(.recursiveDescription) {
          try AssertionRequestGenerator(viewGenerator: viewGenerator).generateRequestsSync()
        }
      }
    }

    #expect(requests.count == 1)
    let request = try #require(requests.first as? AssertionRequest<String>)
    let snapshotDirectory = try #require(request.snapshotDirectory)
    let pathExtension = try #require(request.snapshotting.pathExtension)

    // `verifySnapshot` sanitises the test name and appends the counter and path extension.
    let fileName = SnapshotNameNormalizer.folderComponent(from: request.testName)
    let absolutePath = snapshotDirectory + "/" + fileName + ".1." + pathExtension

    #expect(absolutePath.hasPrefix("/Tests/"))

    return Artifact(repoRelativePath: String(absolutePath.dropFirst(1)))
  }

  /// Compile-time stand-in for the checked-in fixture's `#filePath` (a repo-rooted path);
  /// only the repo-relative suffix matters for path computation.
  private static let fixtureFilePathLiteral: StaticString =
    "/Tests/SnapshotsIntegrationTests/SnapshotTest/LegacySnapshotTestMigration.swift"

  private static var repositoryRootPath: String {
    // #filePath = <root>/Tests/SnapshotsUnitTests/Migration/SnapshotMigrationRewriterNamingParityTests.swift
    URL(fileURLWithPath: #filePath, isDirectory: false)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .path
  }

  private static var legacyFixturePath: String {
    repositoryRootPath + "/Tests/SnapshotsIntegrationTests/SnapshotTest/LegacySnapshotTestMigration.swift"
  }
}
#endif
