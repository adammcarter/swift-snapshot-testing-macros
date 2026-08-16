import Foundation

/// The two images pointfree wrote for one mismatch, carried as paths so a ``SnapshotFailure``
/// can attach them to the Swift Testing result instead of only naming them in its message.
///
/// The paths are captured structurally, from the `diffTool` closure pointfree invokes with
/// both of them (`SnapshotTestingConfiguration.DiffTool`), rather than parsed back out of the
/// human-readable failure message — see ``PointfreeAsserter``.
struct SnapshotFailureArtifacts: Sendable {
  /// The recorded reference the snapshot was compared against.
  let referencePath: String

  /// The image this run produced, written by pointfree into its artifacts directory.
  let failedPath: String

  /// The attachable payloads for this mismatch, in reference-then-newly-taken order.
  ///
  /// A path whose file cannot be read is dropped rather than attached empty: pointfree only
  /// reaches the diff when both files exist, but the artifacts directory is temporary and a
  /// half-attached failure is worse than a failure that just names the paths.
  func attachments() -> [(name: String, data: Data)] {
    [
      ("reference", referencePath),
      ("newly-taken", failedPath),
    ]
    .compactMap { prefix, path in
      guard let data = FileManager.default.contents(atPath: path) else {
        return nil
      }

      return (
        name: "\(prefix)-\(URL(fileURLWithPath: path).lastPathComponent)",
        data: data
      )
    }
  }
}
