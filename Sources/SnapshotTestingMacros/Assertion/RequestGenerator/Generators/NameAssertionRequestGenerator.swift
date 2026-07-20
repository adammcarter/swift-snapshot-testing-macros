import CoreGraphics
import Foundation

struct NameAssertionRequestGenerator: AssertionRequestGenerating {
  let context: AssertionRequestContext

  let traitSize: SizesSnapshotTrait.Size
  let size: CGSize
  let theme: SnapshotTheme
  let displayScale: Double

  private var resolvedContext: AssertionRequestContext {
    guard let pathName = normalizedPathName(from: context.name) else {
      return context
    }

    /*
     The slash-as-subfolder convention applies to configured (parameterized) tests too. Their
     snapshot directory already nests the full slash-aware test folder path (derived from the
     display name in `AssertionRequestGenerator`), so only the name is rewritten to the final
     path segment here — appending the folder again would duplicate it. Either way the raw `/`
     must not leak into the test name, where it would reach the reference file name and
     pointfree's counter key.
     */
    let snapshotDirectory =
      if context.configurationName == nil {
        URL(fileURLWithPath: context.snapshotDirectory, isDirectory: true)
          .appendingPathComponent(pathName.folder, isDirectory: true)
          .path
      }
      else {
        context.snapshotDirectory
      }

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
