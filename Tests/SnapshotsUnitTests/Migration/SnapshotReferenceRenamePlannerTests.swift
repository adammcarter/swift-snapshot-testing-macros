import Foundation
import Testing

@testable import SnapshotMigrationSupport

/**
 The v3 layout moved configured snapshot references from `<TestFile>/<case>/<display>_...`
 to `<TestFile>/<display>/<case>_<display>_...` (see `Refactor configured snapshot resource
 layout`). A 2.x adopter's checked-in references therefore stop resolving after migration,
 and — because a missing reference records rather than fails — the suite goes green while
 comparing against artifacts it just wrote. The planner produces the rename that keeps the
 verified baseline intact, so the post-migration run is a real comparison.
 */
@Suite
struct SnapshotReferenceRenamePlannerTests {
  private let planner = SnapshotReferenceRenamePlanner()

  @Test(
    "Configured references swap their case and display components",
    arguments: [
      (
        "__Snapshots__/ComparisonEntitySnapshotTests/After-Launch-Failed/Entities_min-size_dark.1.png",
        "__Snapshots__/ComparisonEntitySnapshotTests/Entities/After-Launch-Failed_Entities_min-size_dark.1.png"
      ),
      (
        "__Snapshots__/ComparisonShellSnapshotTests/Shell-Empty/Shell_min-size_light.1.png",
        "__Snapshots__/ComparisonShellSnapshotTests/Shell/Shell-Empty_Shell_min-size_light.1.png"
      ),
      // A repetition counter above 1 rides along untouched.
      (
        "__Snapshots__/SuiteTests/Case-One/Display_min-size_light.3.png",
        "__Snapshots__/SuiteTests/Display/Case-One_Display_min-size_light.3.png"
      ),
      // Non-PNG strategies use the same layout.
      (
        "__Snapshots__/SuiteTests/Case-One/Display_min-size_light.1.txt",
        "__Snapshots__/SuiteTests/Display/Case-One_Display_min-size_light.1.txt"
      ),
    ]
  )
  func planRenamesConfiguredReferences(legacyPath: String, expectedPath: String) throws {
    let renames = planner.plan(referencePaths: [legacyPath])

    #expect(renames == [.init(from: legacyPath, to: expectedPath)])
  }

  /**
   v3 also embeds an explicit size's dimensions in the size component, so a suite declaring
   `.sizes(width: 1008, height: 688)` moves from `fixed-size` to `fixed-1008x688`. The
   dimensions are not recoverable from the legacy path, so the caller supplies the resolved
   token per test file from the declaration it just migrated.
   */
  @Test("An explicit size's token is rewritten alongside the layout swap")
  func planRewritesExplicitSizeTokens() throws {
    let legacyPath = "__Snapshots__/ComparisonShellSnapshotTests/Shell-Empty/Shell_fixed-size_light.1.png"

    let renames = planner.plan(
      referencePaths: [legacyPath],
      sizeTokensByTestFile: ["ComparisonShellSnapshotTests": "fixed-1008x688"]
    )

    #expect(
      renames == [
        .init(
          from: legacyPath,
          to: "__Snapshots__/ComparisonShellSnapshotTests/Shell/Shell-Empty_Shell_fixed-1008x688_light.1.png"
        )
      ]
    )
  }

  @Test("A minimum size keeps its token when another test file declares an explicit size")
  func planLeavesMinimumSizeTokensAlone() throws {
    let legacyPath = "__Snapshots__/ComparisonEntitySnapshotTests/After-Launch-Failed/Entities_min-size_dark.1.png"

    let renames = planner.plan(
      referencePaths: [legacyPath],
      sizeTokensByTestFile: ["ComparisonShellSnapshotTests": "fixed-1008x688"]
    )

    #expect(
      renames == [
        .init(
          from: legacyPath,
          to: "__Snapshots__/ComparisonEntitySnapshotTests/Entities/After-Launch-Failed_Entities_min-size_dark.1.png"
        )
      ]
    )
  }

  @Test(
    "References that are already in the v3 layout, or were never configured, are left alone",
    arguments: [
      // Unconfigured reference: no case folder to swap.
      "__Snapshots__/SuiteTests/Display_min-size_light.1.png",
      // Already migrated: the file prefix already repeats the folder name.
      "__Snapshots__/SuiteTests/Display/Case-One_Display_min-size_light.1.png",
    ]
  )
  func planLeavesNonLegacyReferencesUntouched(path: String) throws {
    #expect(planner.plan(referencePaths: [path]).isEmpty)
  }
}
