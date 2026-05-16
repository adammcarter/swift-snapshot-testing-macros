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

  @Test
  func skipsUnreadableFilesAndContinuesScanning() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    try fixture.write(path: "Tests/Readable.swift", contents: "@SnapshotSuite struct Readable {}")
    try fixture.write(path: "Tests/Unreadable.swift", contents: "@SnapshotTest func unreadable() {}")
    try fixture.setPOSIXPermissions(path: "Tests/Unreadable.swift", permissions: 0o000)
    defer { try? fixture.setPOSIXPermissions(path: "Tests/Unreadable.swift", permissions: 0o644) }

    let scanner = ProjectScanner()
    let result = try scanner.scan(projectRoot: fixture.root, maxFileSizeBytes: 2_000_000)

    #expect(result.filesScanned == 2)
    #expect(result.candidateFiles.map(\.relativePath) == ["Tests/Readable.swift"])
  }

  @Test
  func skipsNonUTF8FilesAndContinuesScanning() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    try fixture.write(path: "Tests/Readable.swift", contents: "@SnapshotSuite struct Readable {}")
    try fixture.write(path: "Tests/InvalidEncoding.swift", data: Data([0xFF, 0xFE, 0xFD]))

    let scanner = ProjectScanner()
    let result = try scanner.scan(projectRoot: fixture.root, maxFileSizeBytes: 2_000_000)

    #expect(result.filesScanned == 2)
    #expect(result.candidateFiles.map(\.relativePath) == ["Tests/Readable.swift"])
  }

  @Test
  func throwsDedicatedErrorWhenProjectRootDoesNotExist() {
    let missingRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      .appendingPathComponent("missing-root-\(UUID().uuidString)", isDirectory: true).path

    let scanner = ProjectScanner()

    do {
      _ = try scanner.scan(projectRoot: missingRoot, maxFileSizeBytes: 2_000_000)
      Issue.record("Expected scan to throw for missing root")
    } catch let error as ProjectScannerError {
      #expect(error == .invalidProjectRoot(missingRoot))
    } catch {
      Issue.record("Expected ProjectScannerError, got \(error)")
    }
  }

  @Test
  func throwsDedicatedErrorWhenProjectRootIsUnreadable() throws {
    let fixture = try TempProject.make()
    defer { fixture.cleanup() }

    try fixture.setPOSIXPermissions(path: ".", permissions: 0o000)
    defer { try? fixture.setPOSIXPermissions(path: ".", permissions: 0o700) }

    let scanner = ProjectScanner()

    do {
      _ = try scanner.scan(projectRoot: fixture.root, maxFileSizeBytes: 2_000_000)
      Issue.record("Expected scan to throw for unreadable root")
    } catch let error as ProjectScannerError {
      #expect(error == .invalidProjectRoot(fixture.root))
    } catch {
      Issue.record("Expected ProjectScannerError, got \(error)")
    }
  }
}
