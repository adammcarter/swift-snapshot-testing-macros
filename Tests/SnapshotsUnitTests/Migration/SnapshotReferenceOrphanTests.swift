import Foundation
import Testing

@testable import SnapshotMigrationSupport

/**
 A reference nobody resolves is invisible: it is never compared, never fails, and never reported,
 so it survives every run looking exactly like coverage. Two shapes are decidable without running
 the suite, and both are real failure modes.
 */
@Suite
struct SnapshotReferenceOrphanTests {
  private let migrator = SnapshotReferenceMigrator()

  /// A reference folder whose test file was deleted or renamed. The images stay checked in
  /// forever, inflating the repository and implying coverage that no longer exists.
  @Test("A reference folder with no matching test file is reported")
  func reportsReferencesWithoutATestFile() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }
    try fixture.write(path: "Tests/LiveTests.swift", contents: "// still here")
    try fixture.write(
      path: "Tests/__Snapshots__/LiveTests/Display/Case_Display_min-size_light.1.png",
      contents: "kept"
    )
    try fixture.write(
      path: "Tests/__Snapshots__/DeletedTests/Display/Case_Display_min-size_light.1.png",
      contents: "orphan"
    )

    let orphans = migrator.orphanedReferences(projectRoot: fixture.root)

    #expect(orphans == ["Tests/__Snapshots__/DeletedTests/Display/Case_Display_min-size_light.1.png"])
  }

  /// A reference still in the 2.x layout after an apply run means the rename did not cover it —
  /// the assertion will not resolve it, and because a miss records rather than fails, the suite
  /// would go green while comparing against a freshly written file.
  @Test("A reference left in the 2.x layout is reported")
  func reportsUnmigratedLegacyReferences() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }
    try fixture.write(path: "Tests/SuiteTests.swift", contents: "// present")
    try fixture.write(
      path: "Tests/__Snapshots__/SuiteTests/Case-One/Display_min-size_light.1.png",
      contents: "legacy shaped"
    )

    let stragglers = migrator.unmigratedReferences(projectRoot: fixture.root)

    #expect(stragglers == ["Tests/__Snapshots__/SuiteTests/Case-One/Display_min-size_light.1.png"])
  }

  @Test("A fully migrated project reports neither")
  func cleanProjectIsSilent() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }
    try fixture.write(path: "Tests/SuiteTests.swift", contents: "// present")
    try fixture.write(
      path: "Tests/__Snapshots__/SuiteTests/Display/Case-One_Display_min-size_light.1.png",
      contents: "migrated"
    )

    #expect(migrator.orphanedReferences(projectRoot: fixture.root).isEmpty)
    #expect(migrator.unmigratedReferences(projectRoot: fixture.root).isEmpty)
  }
}
