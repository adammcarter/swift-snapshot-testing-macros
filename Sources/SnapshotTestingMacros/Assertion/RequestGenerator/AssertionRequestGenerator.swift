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

    let folderName: String?
    if let name = viewGenerator.configuration.name {
      folderName = SnapshotNameNormalizer.folderComponent(from: name)
    }
    else {
      folderName = nil
    }

    return .init(
      name: viewGenerator.displayName,
      traitConfiguration: traitConfiguration,
      makeSnapshotView: { try await viewGenerator.makeDecoratedView() },
      snapshotDirectory: makeSnapshotDirectory(
        file: viewGenerator.filePath,
        folderName: folderName
      ),
      fileID: viewGenerator.fileID,
      filePath: viewGenerator.filePath,
      line: viewGenerator.line,
      column: viewGenerator.column
    )
  }

  private func makeSnapshotDirectory(
    file filePath: StaticString,
    folderName: String?
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
      if let folderName {
        $0.appendPathComponent(folderName, isDirectory: true)
      }
    }

    return snapshotDirectory.path
  }
}
