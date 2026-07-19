import Foundation
import Testing

@testable import SnapshotMigrationSupport

@Suite
struct SnapshotReferenceMigratorTests {
  private let migrator = SnapshotReferenceMigrator()

  @Test("An explicit suite size supplies the token the reference path cannot carry")
  func readsExplicitSizeFromTheMigratedDeclaration() throws {
    let source = """
      @Suite(.sizes(width: 1008, height: 688))
      struct ComparisonShellSnapshotTests {}
      """
    let file = ScannedFile(
      absolutePath: "/tmp/ImageDiffSnapshotTests/ComparisonShellSnapshotTests.swift",
      relativePath: "ImageDiffSnapshotTests/ComparisonShellSnapshotTests.swift",
      contents: source
    )

    #expect(
      migrator.sizeTokensByTestFile(scannedFiles: [file])
        == ["ComparisonShellSnapshotTests": "fixed-1008x688"]
    )
  }

  @Test("A minimum-sized suite contributes no token, leaving min-size references alone")
  func ignoresSuitesWithoutAnExplicitSize() throws {
    let file = ScannedFile(
      absolutePath: "/tmp/Entities.swift",
      relativePath: "Entities.swift",
      contents: "@Suite(.sizes(.minimum))\nstruct Entities {}"
    )

    #expect(migrator.sizeTokensByTestFile(scannedFiles: [file]).isEmpty)
  }

  @Test("A dry run plans the renames without touching the files")
  func dryRunLeavesReferencesInPlace() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }
    let legacy = "Tests/__Snapshots__/SuiteTests/Case-One/Display_min-size_light.1.png"
    try fixture.write(path: legacy, contents: "reference")

    let outcome = migrator.migrate(projectRoot: fixture.root, sizeTokensByTestFile: [:], dryRun: true)

    #expect(outcome.planned.count == 1)
    #expect(outcome.applied == 0)
    #expect(FileManager.default.fileExists(atPath: fixture.root + "/" + legacy))
  }

  @Test("Applying moves each reference into the v3 layout, size token included")
  func applyRenamesReferences() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }
    try fixture.write(
      path: "Tests/__Snapshots__/SuiteTests/Case-One/Display_fixed-size_light.1.png",
      contents: "reference"
    )

    let outcome = migrator.migrate(
      projectRoot: fixture.root,
      sizeTokensByTestFile: ["SuiteTests": "fixed-320x180"],
      dryRun: false
    )

    #expect(outcome.applied == 1)
    #expect(outcome.failures.isEmpty)
    let migrated = fixture.root
      + "/Tests/__Snapshots__/SuiteTests/Display/Case-One_Display_fixed-320x180_light.1.png"
    #expect(FileManager.default.fileExists(atPath: migrated))
  }

  /// Overwriting would destroy the evidence the adopter is meant to review, so a collision is
  /// reported and both files are left where they are.
  @Test("A destination that already exists is reported rather than overwritten")
  func refusesToOverwriteAnExistingDestination() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }
    try fixture.write(
      path: "Tests/__Snapshots__/SuiteTests/Case-One/Display_min-size_light.1.png",
      contents: "legacy"
    )
    try fixture.write(
      path: "Tests/__Snapshots__/SuiteTests/Display/Case-One_Display_min-size_light.1.png",
      contents: "already migrated"
    )

    let outcome = migrator.migrate(projectRoot: fixture.root, sizeTokensByTestFile: [:], dryRun: false)

    #expect(outcome.applied == 0)
    #expect(outcome.failures.count == 1)
    #expect(outcome.failures[0].contains("destination-exists"))
  }
}
