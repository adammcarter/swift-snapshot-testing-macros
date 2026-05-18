import CoreGraphics
import Foundation

struct NameAssertionRequestGenerator: AssertionRequestGenerating {
  let context: AssertionRequestContext

  let traitSize: SizesSnapshotTrait.Size
  let size: CGSize
  let theme: SnapshotTheme
  let displayScale: Double

  private var resolvedContext: AssertionRequestContext {
    guard context.configurationName == nil,
          let pathName = normalizedPathName(from: context.name)
    else {
      return context
    }

    let snapshotDirectory = URL(fileURLWithPath: context.snapshotDirectory, isDirectory: true)
      .appendingPathComponent(pathName.folder, isDirectory: true)
      .path

    return AssertionRequestContext(
      name: pathName.file,
      configurationName: context.configurationName,
      traitConfiguration: context.traitConfiguration,
      makeSnapshotView: context.makeSnapshotView,
      snapshotDirectory: snapshotDirectory,
      fileID: context.fileID,
      filePath: context.filePath,
      line: context.line,
      column: context.column
    )
  }

  /**
   The following, in order, joined by an underscore.
   Any subcomponent should replace spaces with a hyphen.

   test display name, configuration name, size trait, theme trait
   */
  private func testName(for context: AssertionRequestContext) -> String {
    [
      context.configurationName,
      context.name,
      traitSize.testNameDescription,
      theme.testNameDescription,
    ]
    .compactMap { $0 }
    .joined(separator: "_")
  }

  func generateRequestsSync() throws -> [any AssertionRequesting] {
    let resolvedContext = resolvedContext

    let base = StrategyAssertionRequestGenerator(
      context: resolvedContext,
      size: size,
      theme: theme,
      displayScale: displayScale,
      testName: testName(for: resolvedContext)
    )

    return try base.generateRequestsSync()
  }

  private func normalizedPathName(from name: String) -> (folder: String, file: String)? {
    let normalizedComponents = name
      .split(separator: "/", omittingEmptySubsequences: true)
      .map(String.init)
      .map(SnapshotNameNormalizer.folderComponent(from:))
      .filter { !$0.isEmpty }

    guard normalizedComponents.count >= 2 else {
      return nil
    }

    let folder = normalizedComponents.dropLast().joined(separator: "/")
    let file = normalizedComponents[normalizedComponents.index(before: normalizedComponents.endIndex)]
    return (folder: folder, file: file)
  }
}

@MainActor
extension SnapshotTheme {
  var testNameDescription: String {
    #if canImport(UIKit)
    switch self {
      case .dark: "dark"
      case .light: "light"
      case .unspecified: "unspecified"
      @unknown default: "unknown"
    }
    #elseif canImport(AppKit)
    switch self.name {
      case .darkAqua: "dark"
      case .aqua: "light"
      default: "unknown"
    }
    #endif
  }
}
