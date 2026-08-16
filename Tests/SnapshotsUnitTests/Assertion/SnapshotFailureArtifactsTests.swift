#if os(macOS)
import AppKit
import Foundation
import SnapshotTesting
import Testing

@testable import SnapshotTestingMacros

/// Covers the images a mismatch carries back so Swift Testing can attach them to the failure.
///
/// The snapshotting strategy renders a solid colour rather than a real view hierarchy: the
/// assertion under test is what the failure carries, not what AppKit draws, and a flat fill is
/// byte-identical on every machine so a mismatch here is always the intended one.
@MainActor
struct SnapshotFailureArtifactsTests {

  @Test
  func mismatchCarriesTheReferenceAndTheNewlyTakenImage() throws {
    let directory = try makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    _ = run(color: .red, in: directory, record: .all)
    let failures = run(color: .green, in: directory, record: .never)

    let artifacts = try #require(failures.first?.artifacts)
    let attachments = artifacts.attachments()

    #expect(
      attachments.map(\.name) == [
        "reference-artifacts.1.png",
        "newly-taken-artifacts.1.png",
      ]
    )
    #expect(attachments.allSatisfy { !$0.data.isEmpty })
    // The two images are what disagreed, so they must not be the same bytes.
    #expect(attachments[0].data != attachments[1].data)
  }

  @Test
  func matchingSnapshotCarriesNothingToAttach() throws {
    let directory = try makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    _ = run(color: .red, in: directory, record: .all)
    let failures = run(color: .red, in: directory, record: .never)

    #expect(failures.isEmpty)
  }

  /// On the first record there is no reference on disk, so there is nothing to attach —
  /// pointfree never reaches the diff and the failure must not point at a missing file.
  @Test
  func missingReferenceCarriesNothingToAttach() throws {
    let directory = try makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let failures = run(color: .red, in: directory, record: .never)

    #expect(failures.count == 1)
    #expect(failures.first?.artifacts == nil)
  }

  // MARK: - Support

  private func run(
    color: NSColor,
    in directory: URL,
    record: SnapshotTestingConfiguration.Record
  ) -> [SnapshotFailure] {
    let request = AssertionRequest(
      view: SnapshotViewController(),
      snapshotting: makeSnapshotting(color: color),
      snapshotDirectory: directory.path,
      testName: "artifacts",
      fileID: #fileID,
      filePath: #filePath,
      line: 1,
      column: 1
    )

    // A fresh context per run restarts pointfree's `.N` identifier at `.1`, so every run in
    // this test resolves the same reference file.
    return TaskLocalSnapshotExecutionContext.$current.withValue(
      SnapshotExecutionContext(function: "artifacts")
    ) {
      SnapshotTesting.withSnapshotTesting(record: record) {
        Asserter().collectFailuresSync(from: [request])
      }
    }
  }

  private func makeSnapshotting(color: NSColor) -> Snapshotting<SnapshotViewController, NSImage> {
    Snapshotting<NSImage, NSImage>.image.pullback { _ in
      let image = NSImage(size: .init(width: 4, height: 4))
      image.lockFocus()
      color.setFill()
      NSRect(x: 0, y: 0, width: 4, height: 4).fill()
      image.unlockFocus()
      return image
    }
  }

  private func makeTemporaryDirectory() throws -> URL {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      .appendingPathComponent("SnapshotFailureArtifactsTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }
}
#endif
