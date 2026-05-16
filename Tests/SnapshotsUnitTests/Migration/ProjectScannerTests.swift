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
}
