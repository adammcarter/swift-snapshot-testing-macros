import Foundation
import SnapshotSupport
import SnapshotTesting

@MainActor
struct AssertionRequestGenerator {
  let viewGenerator: any SnapshotViewGenerating

  func generateRequestsSync() throws -> [any AssertionRequesting] {
    let context = try makeContext(with: viewGenerator)

    let requestGenerator = SizeAssertionRequestGenerator(context: context)

    return try requestGenerator.generateRequestsSync()
  }

  func generateRequests() async throws -> [any AssertionRequesting] {
    try generateRequestsSync()
  }

  private func makeContext(
    with viewGenerator: some SnapshotViewGenerating
  ) throws -> AssertionRequestContext {
    let traitConfiguration = AssertionRequestContext.TraitConfiguration(
      sizes: SizesSnapshotTrait.current,
      theme: ThemeSnapshotTrait.current,
      strategy: StrategySnapshotTrait.current
    )

    let configurationName = Self.normalizedNameComponent(from: viewGenerator.configuration.name)

    /*
     Slash-aware so the slash-as-subfolder display-name convention means the same thing for
     configured (parameterized) tests as for plain ones: "Menu/Item" nests Menu/Item/ under
     the test file's snapshot folder instead of flattening to a single "Menu-Item" folder.
     `NameAssertionRequestGenerator` then keeps only the final segment as the artifact name.
     */
    let testFolderName = configurationName.flatMap { _ in
      Self.normalizedPathName(from: viewGenerator.displayName)
    }

    return .init(
      name: viewGenerator.displayName,
      configurationName: configurationName,
      traitConfiguration: traitConfiguration,
      makeSnapshotView: { try viewGenerator.makeDecoratedView() },
      snapshotDirectory: Self.makeSnapshotDirectory(
        filePath: viewGenerator.filePath,
        testFolderName: testFolderName
      ),
      fileID: viewGenerator.fileID,
      filePath: viewGenerator.filePath,
      line: viewGenerator.line,
      column: viewGenerator.column
    )
  }

  static func makeSnapshotDirectory(
    filePath: StaticString,
    testFolderName: String?
  ) -> String {
    let fileUrl = URL(fileURLWithPath: "\(filePath)", isDirectory: false)

    let fileName =
      fileUrl
      .deletingPathExtension()
      .lastPathComponent

    let snapshotsBaseUrl =
      fileUrl
      .deletingLastPathComponent()
      .appendingPathComponent("__Snapshots__")
      .appendingPathComponent(fileName)

    let snapshotDirectory = with(snapshotsBaseUrl) {
      if let testFolderName {
        $0.appendPathComponent(testFolderName, isDirectory: true)
      }
    }

    return snapshotDirectory.path
  }

  private static func normalizedNameComponent(from name: String?) -> String? {
    guard let name else {
      return nil
    }

    let normalized = SnapshotNameNormalizer.folderComponent(from: name)
    return normalized.isEmpty ? nil : normalized
  }

  private static func normalizedPathName(from name: String?) -> String? {
    guard let name else {
      return nil
    }

    let normalized = SnapshotNameNormalizer.folderPath(from: name)
    return normalized.isEmpty ? nil : normalized
  }
}
