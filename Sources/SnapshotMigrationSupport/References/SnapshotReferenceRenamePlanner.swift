import Foundation

/**
 Plans the on-disk reference renames that accompany a source migration.

 The v3 layout moved configured (parameterised) snapshot references from
 `<TestFile>/<case>/<display>_<size>_<theme>.<n>.<ext>` to
 `<TestFile>/<display>/<case>_<display>_<size>_<theme>.<n>.<ext>`. Migrating the source
 without migrating these files leaves every checked-in reference unreachable; because a
 missing reference records rather than fails, the adopter's suite then reports green while
 comparing against artifacts it wrote moments earlier. Renaming preserves the verified
 baseline, so the first post-migration run is a genuine comparison.

 The mapping is derivable from the legacy path alone — it already carries both components —
 so the planner needs no knowledge of the migrated declarations.
 */
public struct SnapshotReferenceRenamePlanner: Sendable {
  public struct Rename: Equatable, Sendable {
    public let from: String
    public let to: String

    public init(from: String, to: String) {
      self.from = from
      self.to = to
    }
  }

  private static let snapshotsDirectoryName = "__Snapshots__"

  public init() {}

  /// The v2 token for an explicitly sized snapshot. v3 replaces it with the declaration's
  /// own dimensions, which the legacy path does not carry — hence `sizeTokensByTestFile`.
  private static let legacyExplicitSizeToken = "fixed-size"

  public func plan(
    referencePaths: [String],
    sizeTokensByTestFile: [String: String] = [:]
  ) -> [Rename] {
    referencePaths.compactMap { rename(forLegacyPath: $0, sizeTokensByTestFile: sizeTokensByTestFile) }
  }

  private func rename(forLegacyPath path: String, sizeTokensByTestFile: [String: String]) -> Rename? {
    let components = path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)

    guard
      let snapshotsIndex = components.lastIndex(of: Self.snapshotsDirectoryName),
      /*
       Exactly `<TestFile>/<case>/<file>`. A shallower path is an unconfigured reference with
       no case folder to swap; a deeper one is a slash-delimited display name, whose nesting
       this planner deliberately leaves alone rather than guess at.
       */
      components.distance(from: snapshotsIndex, to: components.endIndex) == 4
    else {
      return nil
    }

    let caseName = components[components.index(snapshotsIndex, offsetBy: 2)]
    let fileName = components[components.index(before: components.endIndex)]
    let nameComponents = fileName.split(separator: "_", omittingEmptySubsequences: false).map(String.init)

    guard let displayName = nameComponents.first, !displayName.isEmpty else {
      return nil
    }

    /*
     In the v3 layout the case name leads the file name and the display name follows it, so a
     second component matching the containing folder means this reference has already been
     migrated. Skipping it keeps repeat runs idempotent.
     */
    guard nameComponents.count < 2 || nameComponents[1] != caseName else {
      return nil
    }

    let testFileName = components[components.index(after: snapshotsIndex)]
    let resizedComponents =
      if let sizeToken = sizeTokensByTestFile[testFileName] {
        nameComponents.map { $0 == Self.legacyExplicitSizeToken ? sizeToken : $0 }
      }
      else {
        nameComponents
      }

    let migratedFileName = "\(caseName)_\(resizedComponents.joined(separator: "_"))"
    let destination = components
      .prefix(components.distance(from: components.startIndex, to: snapshotsIndex) + 2)
      + [displayName, migratedFileName]

    return Rename(from: path, to: destination.joined(separator: "/"))
  }
}
