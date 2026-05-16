import Foundation
import Testing

@testable import SnapshotMigrationSupport

@Suite
struct ProjectScannerTests {
  @Test
  func excludesNonProjectDirectoriesSortsDeterministicallyAndFiltersCandidates() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    try fixture.write(path: "Tests/B.swift", contents: "@SnapshotTest func b() {}")
    try fixture.write(path: "Tests/A.swift", contents: "@SnapshotSuite struct A {}")
    try fixture.write(path: "Tests/C.swift", contents: "struct C {}")
    try fixture.write(path: ".git/Ignored.swift", contents: "@SnapshotSuite struct Ignored {}")
    try fixture.write(path: "node_modules/Ignored.swift", contents: "@SnapshotTest func ignored() {}")
    try fixture.write(path: "Pods/Ignored.swift", contents: "@SnapshotSuite struct PodIgnored {}")

    let scanner = ProjectScanner()
    let result = try scanner.scan(projectRoot: fixture.root, maxFileSizeBytes: 2_000_000)

    #expect(result.filesScanned == 3)
    #expect(result.candidateFiles.map(\.relativePath) == ["Tests/A.swift", "Tests/B.swift"])
  }

  @Test
  func excludesOversizedSwiftFilesFromCandidates() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    try fixture.write(path: "Tests/Small.swift", contents: "@SnapshotSuite struct Small {}")
    let oversized = "@SnapshotSuite struct Huge {}\n" + String(repeating: "x", count: 4_096)
    try fixture.write(path: "Tests/Huge.swift", contents: oversized)

    let scanner = ProjectScanner()
    let result = try scanner.scan(projectRoot: fixture.root, maxFileSizeBytes: 256)

    #expect(result.filesScanned == 2)
    #expect(result.candidateFiles.map(\.relativePath) == ["Tests/Small.swift"])
  }

  @Test
  func skipsSymlinkedDirectoriesDuringTraversal() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    try fixture.write(path: "Tests/Real.swift", contents: "@SnapshotTest func real() {}")

    let rootURL = URL(fileURLWithPath: fixture.root, isDirectory: true)
    let symlinkTarget = rootURL
      .deletingLastPathComponent()
      .appendingPathComponent("snapshot-migration-symlink-target-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: symlinkTarget, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: symlinkTarget) }

    let linkedFile = symlinkTarget.appendingPathComponent("Linked.swift")
    try "@SnapshotSuite struct Linked {}".write(to: linkedFile, atomically: true, encoding: .utf8)

    let symlinkPath = rootURL.appendingPathComponent("LinkedDirectory").path
    try FileManager.default.createSymbolicLink(atPath: symlinkPath, withDestinationPath: symlinkTarget.path)

    let scanner = ProjectScanner()
    let result = try scanner.scan(projectRoot: fixture.root, maxFileSizeBytes: 2_000_000)

    #expect(result.filesScanned == 1)
    #expect(result.candidateFiles.map(\.relativePath) == ["Tests/Real.swift"])
  }
}
