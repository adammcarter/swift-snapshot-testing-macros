import Foundation
import SnapshotSupport
import SnapshotTesting

@MainActor
struct AssertionRequestGenerator {
  let viewGenerator: any SnapshotViewGenerating

  func generateRequests() async throws -> [any AssertionRequesting] {
    let context = try await makeContext(with: viewGenerator)

    let requestGenerator = SizeAssertionRequestGenerator(context: context)

    return try await requestGenerator.generateRequests()
  }

  private func makeContext(
    with viewGenerator: some SnapshotViewGenerating
  ) async throws -> AssertionRequestContext {
    let traitConfiguration = AssertionRequestContext.TraitConfiguration(
      sizes: SizesSnapshotTrait.current,
      theme: ThemeSnapshotTrait.current,
      strategy: StrategySnapshotTrait.current
    )

    let configurationName = Self.normalizedNameComponent(from: viewGenerator.configuration.name)
    let testFolderName = configurationName.flatMap { _ in
      Self.normalizedNameComponent(from: viewGenerator.displayName)
    }

    return .init(
      name: viewGenerator.displayName,
      configurationName: configurationName,
      traitConfiguration: traitConfiguration,
      makeSnapshotView: { try await viewGenerator.makeDecoratedView() },
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
}
