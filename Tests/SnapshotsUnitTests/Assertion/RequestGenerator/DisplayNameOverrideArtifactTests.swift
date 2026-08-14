#if os(macOS)
import AppKit
import Testing

@testable import SnapshotTestingMacros

/// Proves the display-name disambiguation the suite macro emits for multi-test named suites
/// actually resolves distinct reference artifacts end to end.
///
/// On the legacy path the artifact identity is `snapshotDirectory` + `testName`, both derived
/// from the generator's display name. Two tests falling back to the same suite display name
/// used to fight over one reference file; the generated `__overridingDisplayName(of:with:)`
/// wrapper must give each test its own artifact identity.
@MainActor
@Suite
struct DisplayNameOverrideArtifactTests {

  @Test
  func sharedSuiteDisplayNameCollidesWithoutTheOverride() throws {
    let firstArtifacts = try artifactIdentities(for: makeLegacyGenerator())
    let secondArtifacts = try artifactIdentities(for: makeLegacyGenerator())

    #expect(firstArtifacts.isEmpty == false)
    #expect(firstArtifacts == secondArtifacts)
  }

  @Test
  func twoTestsInOneNamedSuiteResolveDistinctArtifacts() throws {
    let first = __overridingDisplayName(
      of: makeLegacyGenerator(),
      with: "Some name/makeFirstView"
    )
    let second = __overridingDisplayName(
      of: makeLegacyGenerator(),
      with: "Some name/makeSecondView"
    )

    let firstArtifacts = try artifactIdentities(for: first)
    let secondArtifacts = try artifactIdentities(for: second)

    #expect(firstArtifacts.isEmpty == false)
    #expect(secondArtifacts.isEmpty == false)
    #expect(firstArtifacts.isDisjoint(with: secondArtifacts))
  }

  @Test
  func overrideKeepsLocationAndConfigurationMetadata() throws {
    let generator = __overridingDisplayName(
      of: makeLegacyGenerator(),
      with: "Some name/makeFirstView"
    )

    let resolved = try #require(generator as? SnapshotViewGenerator<Void>)

    #expect(resolved.displayName == "Some name/makeFirstView")
    #expect(resolved.fileID.description == "fileID")
    #expect(resolved.filePath.description == "/tmp/MySuiteTests.swift")
    #expect(resolved.line == 12)
    #expect(resolved.column == 3)

    let viewController = try resolved.makeViewController(())
    #expect(viewController.view != nil)
  }

  private func makeLegacyGenerator() -> SnapshotViewGenerator<Void> {
    SnapshotViewGenerator<Void>(
      displayName: "Some name",
      configuration: .none,
      makeValue: { _ in
        let controller = SnapshotViewController()
        controller.view = SnapshotView(frame: .init(x: 0, y: 0, width: 10, height: 10))
        return controller
      },
      fileID: "fileID",
      filePath: "/tmp/MySuiteTests.swift",
      line: 12,
      column: 3
    )
  }

  private func artifactIdentities(
    for generator: some SnapshotViewGenerating
  ) throws -> Set<String> {
    let requests = try AssertionRequestGenerator(viewGenerator: generator).generateRequestsSync()

    return Set(requests.map { "\($0.snapshotDirectory)/\($0.testName)" })
  }
}
#endif
