import Foundation

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

    var swiftFiles: [(url: URL, relativePath: String)] = []
    try collectSwiftFiles(in: rootURL, rootURL: rootURL, fileManager: fileManager, output: &swiftFiles)

    let orderedFiles = swiftFiles.sorted { $0.relativePath < $1.relativePath }

    var filesScanned = 0
    var candidates: [ScannedFile] = []

    for file in orderedFiles {
      filesScanned += 1

      let resourceValues = try file.url.resourceValues(forKeys: [.fileSizeKey])
      guard (resourceValues.fileSize ?? 0) <= maxFileSizeBytes else { continue }

      let contents = try String(contentsOf: file.url, encoding: .utf8)
      guard contents.contains("@SnapshotSuite") || contents.contains("@SnapshotTest") else { continue }

      candidates.append(
        ScannedFile(
          absolutePath: file.url.path,
          relativePath: file.relativePath,
          contents: contents
        )
      )
    }

    return ScanResult(filesScanned: filesScanned, candidateFiles: candidates)
  }

  private func collectSwiftFiles(
    in directory: URL,
    rootURL: URL,
    fileManager: FileManager,
    output: inout [(url: URL, relativePath: String)]
  ) throws {
    let entries = try fileManager.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey],
      options: []
    )
    .sorted {
      relativePath(for: $0, rootURL: rootURL) < relativePath(for: $1, rootURL: rootURL)
    }

    for entry in entries {
      let relative = relativePath(for: entry, rootURL: rootURL)
      let values = try entry.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey])

      if values.isDirectory == true {
        guard values.isSymbolicLink != true else { continue }
        guard !Self.excludedDirectories.contains(entry.lastPathComponent) else { continue }
        try collectSwiftFiles(in: entry, rootURL: rootURL, fileManager: fileManager, output: &output)
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
