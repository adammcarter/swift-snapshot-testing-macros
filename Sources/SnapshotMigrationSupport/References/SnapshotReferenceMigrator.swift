import Foundation

/**
 Applies the reference renames that accompany a source migration.

 Walks every `__Snapshots__` directory under the project root, asks
 `SnapshotReferenceRenamePlanner` for the v2 → v3 moves, and performs them. Without this the
 migrated assertions look for artifacts that are not there, and because a missing reference
 records rather than fails, the adopter's first run reports green while comparing against
 files it wrote moments earlier. Renaming turns that silent re-record into a reviewable diff.

 The explicit-size token (`fixed-size` → `fixed-<width>x<height>`) is not recoverable from the
 reference path, so it is read from the declaration the migration just rewrote.
 */
public struct SnapshotReferenceMigrator: Sendable {
  public struct Outcome: Equatable, Sendable {
    public let planned: [SnapshotReferenceRenamePlanner.Rename]
    public let applied: Int
    public let failures: [String]

    public init(planned: [SnapshotReferenceRenamePlanner.Rename], applied: Int, failures: [String]) {
      self.planned = planned
      self.applied = applied
      self.failures = failures
    }
  }

  private static let snapshotsDirectoryName = "__Snapshots__"

  public init() {}

  /**
   Reads the explicit size declared by each scanned source file, keyed by the file's base name.

   Reference folders are named after the test file, so the base name is the join between a
   migrated declaration and the artifacts it owns. Only a fully fixed size changes token, which
   is the single-line form the legacy suites used.
   */
  public func sizeTokensByTestFile(scannedFiles: [ScannedFile]) -> [String: String] {
    var tokens: [String: String] = [:]

    for file in scannedFiles {
      guard let size = Self.explicitSize(in: file.contents) else { continue }
      let testFileName = (file.relativePath as NSString).lastPathComponent
      let baseName = (testFileName as NSString).deletingPathExtension
      tokens[baseName] = "fixed-\(size.width)x\(size.height)"
    }

    return tokens
  }

  public func migrate(
    projectRoot: String,
    sizeTokensByTestFile: [String: String],
    dryRun: Bool
  ) -> Outcome {
    let referencePaths = Self.referencePaths(projectRoot: projectRoot)
    let planned = SnapshotReferenceRenamePlanner().plan(
      referencePaths: referencePaths,
      sizeTokensByTestFile: sizeTokensByTestFile
    )

    guard !dryRun else {
      return Outcome(planned: planned, applied: 0, failures: [])
    }

    let fileManager = FileManager.default
    var applied = 0
    var failures: [String] = []

    for rename in planned {
      let source = URL(fileURLWithPath: projectRoot).appendingPathComponent(rename.from)
      let destination = URL(fileURLWithPath: projectRoot).appendingPathComponent(rename.to)

      do {
        try fileManager.createDirectory(
          at: destination.deletingLastPathComponent(),
          withIntermediateDirectories: true
        )
        /*
         An existing destination means the reference has already been migrated, or two legacy
         artifacts collapse onto one v3 name. Either way, overwriting would destroy evidence
         silently, so report it and leave both files in place.
         */
        guard !fileManager.fileExists(atPath: destination.path) else {
          failures.append("\(rename.from) destination-exists \(rename.to) already exists")
          continue
        }
        try fileManager.moveItem(at: source, to: destination)
        applied += 1
      } catch {
        failures.append("\(rename.from) rename-failed \(error.localizedDescription)")
      }
    }

    return Outcome(planned: planned, applied: applied, failures: failures)
  }

  // MARK: - Orphan detection

  /**
   References whose owning test file no longer exists.

   The reference folder is named after the test file, so a folder with no matching `.swift`
   anywhere in the project belongs to a test that was deleted or renamed. Nothing resolves these
   images, so they are never compared and never fail — they simply persist, inflating the
   repository and implying coverage that no longer exists.
   */
  public func orphanedReferences(projectRoot: String) -> [String] {
    let testFileNames = Set(
      Self.swiftFileNames(projectRoot: projectRoot).map { ($0 as NSString).deletingPathExtension }
    )

    return Self.referencePaths(projectRoot: projectRoot).filter { path in
      guard let owner = Self.owningTestFileName(of: path) else { return false }
      return !testFileNames.contains(owner)
    }
  }

  /**
   References still in the 2.x layout after an apply run.

   The rename should have moved every one of these. Any that remain will not be resolved by the
   migrated assertions, and because a missing reference records rather than fails, the suite
   would report green while comparing against artifacts it had just written.
   */
  public func unmigratedReferences(projectRoot: String) -> [String] {
    SnapshotReferenceRenamePlanner()
      .plan(referencePaths: Self.referencePaths(projectRoot: projectRoot))
      .map(\.from)
  }

  private static func owningTestFileName(of path: String) -> String? {
    let components = path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)

    guard
      let snapshotsIndex = components.lastIndex(of: snapshotsDirectoryName),
      components.index(after: snapshotsIndex) < components.endIndex
    else {
      return nil
    }

    return components[components.index(after: snapshotsIndex)]
  }

  private static func swiftFileNames(projectRoot: String) -> [String] {
    let rootURL = URL(fileURLWithPath: projectRoot).standardizedFileURL
    guard
      let enumerator = FileManager.default.enumerator(
        at: rootURL,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
      )
    else {
      return []
    }

    return enumerator.compactMap { element in
      guard let url = element as? URL, url.pathExtension == "swift" else { return nil }
      return url.lastPathComponent
    }
  }

  // MARK: - Discovery

  private static func referencePaths(projectRoot: String) -> [String] {
    let rootURL = URL(fileURLWithPath: projectRoot).standardizedFileURL
    let fileManager = FileManager.default

    guard
      let enumerator = fileManager.enumerator(
        at: rootURL,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
      )
    else {
      return []
    }

    var paths: [String] = []
    let rootPrefix = rootURL.path.hasSuffix("/") ? rootURL.path : rootURL.path + "/"

    for case let url as URL in enumerator {
      guard
        url.pathComponents.contains(snapshotsDirectoryName),
        (try? url.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true
      else {
        continue
      }

      let path = url.standardizedFileURL.path
      guard path.hasPrefix(rootPrefix) else { continue }
      paths.append(String(path.dropFirst(rootPrefix.count)))
    }

    return paths.sorted()
  }

  // MARK: - Size parsing

  private static func explicitSize(in source: String) -> (width: String, height: String)? {
    let pattern = #"\.sizes\(\s*width:\s*([0-9]+(?:\.[0-9]+)?)\s*,\s*height:\s*([0-9]+(?:\.[0-9]+)?)"#

    guard
      let regex = try? NSRegularExpression(pattern: pattern),
      let match = regex.firstMatch(in: source, range: NSRange(source.startIndex..., in: source)),
      let widthRange = Range(match.range(at: 1), in: source),
      let heightRange = Range(match.range(at: 2), in: source)
    else {
      return nil
    }

    return (
      width: normalisedLength(String(source[widthRange])),
      height: normalisedLength(String(source[heightRange]))
    )
  }

  /// Mirrors the runtime's reference-name formatting: an integral value drops its fraction, and a
  /// fractional one encodes its decimal point as `p` so it can never emit a field-delimiting `-`.
  private static func normalisedLength(_ literal: String) -> String {
    guard let value = Double(literal) else { return literal }

    if value == value.rounded() {
      return String(Int(value))
    }

    return literal.replacingOccurrences(of: ".", with: "p")
  }
}
