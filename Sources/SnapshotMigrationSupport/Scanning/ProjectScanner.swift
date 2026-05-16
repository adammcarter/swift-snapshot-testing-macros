import Foundation

public enum ProjectScannerError: Error, Equatable {
  case invalidProjectRoot(String)
}

public struct ScannedFile: Equatable {
  public let absolutePath: String
  public let relativePath: String
  public let contents: String

  public init(absolutePath: String, relativePath: String, contents: String) {
    self.absolutePath = absolutePath
    self.relativePath = relativePath
    self.contents = contents
  }
}

public struct ScanResult: Equatable {
  public let filesScanned: Int
  public let candidateFiles: [ScannedFile]

  public init(filesScanned: Int, candidateFiles: [ScannedFile]) {
    self.filesScanned = filesScanned
    self.candidateFiles = candidateFiles
  }
}

public struct ProjectScanner {
  private static let excludedDirectories: Set<String> = [
    ".git", ".build", ".swiftpm", "DerivedData", "Pods", "Carthage",
    "node_modules", ".venv", "vendor", "build", "dist",
  ]

  public init() {}

  public func scan(projectRoot: String, maxFileSizeBytes: Int) throws -> ScanResult {
    let rootURL = URL(fileURLWithPath: projectRoot).standardizedFileURL.resolvingSymlinksInPath()
    let fileManager = FileManager.default
    try validateProjectRoot(rootURL, originalProjectRoot: projectRoot, fileManager: fileManager)

    var swiftFiles: [(url: URL, relativePath: String)] = []
    collectSwiftFiles(in: rootURL, rootURL: rootURL, fileManager: fileManager, output: &swiftFiles)

    var filesScanned = 0
    var candidates: [ScannedFile] = []

    for file in swiftFiles {
      filesScanned += 1

      guard
        let resourceValues = try? file.url.resourceValues(forKeys: [.fileSizeKey]),
        (resourceValues.fileSize ?? 0) <= maxFileSizeBytes
      else {
        continue
      }

      guard let contents = try? String(contentsOf: file.url, encoding: .utf8) else { continue }
      guard contents.contains("@SnapshotSuite") || contents.contains("@SnapshotTest") else { continue }

      candidates.append(
        ScannedFile(
          absolutePath: file.url.path,
          relativePath: file.relativePath,
          contents: contents
        )
      )
    }

    let sortedCandidates = candidates.sorted { $0.relativePath < $1.relativePath }
    return ScanResult(filesScanned: filesScanned, candidateFiles: sortedCandidates)
  }

  private func validateProjectRoot(_ rootURL: URL, originalProjectRoot: String, fileManager: FileManager) throws {
    let path = rootURL.path
    var isDirectory = ObjCBool(false)
    guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else {
      throw ProjectScannerError.invalidProjectRoot(originalProjectRoot)
    }

    guard
      let values = try? rootURL.resourceValues(forKeys: [.isReadableKey]),
      values.isReadable == true
    else {
      throw ProjectScannerError.invalidProjectRoot(originalProjectRoot)
    }

    guard (try? fileManager.contentsOfDirectory(atPath: path)) != nil else {
      throw ProjectScannerError.invalidProjectRoot(originalProjectRoot)
    }
  }

  private func collectSwiftFiles(
    in directory: URL,
    rootURL: URL,
    fileManager: FileManager,
    output: inout [(url: URL, relativePath: String)]
  ) {
    let directoryResourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey]

    guard
      let entries = try? fileManager.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: Array(directoryResourceKeys),
        options: []
      )
      .sorted(by: {
        relativePath(for: $0, rootURL: rootURL) < relativePath(for: $1, rootURL: rootURL)
      })
    else {
      return
    }

    for entry in entries {
      let relative = relativePath(for: entry, rootURL: rootURL)
      guard
        let values = try? entry.resourceValues(forKeys: directoryResourceKeys)
      else {
        continue
      }

      if values.isDirectory == true {
        guard values.isSymbolicLink != true else { continue }
        guard !Self.excludedDirectories.contains(entry.lastPathComponent) else { continue }
        collectSwiftFiles(in: entry, rootURL: rootURL, fileManager: fileManager, output: &output)
        continue
      }

      guard values.isRegularFile == true, entry.pathExtension == "swift" else { continue }
      output.append((url: entry, relativePath: relative))
    }
  }

  private func relativePath(for url: URL, rootURL: URL) -> String {
    let rootPath = rootURL.standardizedFileURL.resolvingSymlinksInPath().path
    let path = url.standardizedFileURL.resolvingSymlinksInPath().path

    guard path.hasPrefix(rootPath) else {
      return path
    }

    let relative = path.dropFirst(rootPath.count)
    if relative.hasPrefix("/") {
      return String(relative.dropFirst())
    }

    return String(relative)
  }
}
