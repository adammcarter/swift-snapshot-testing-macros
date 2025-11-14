import Foundation
import SnapshotSupport
import SnapshotTesting

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct StrategyAssertionRequestGenerator: AssertionRequestGenerating {
  let context: AssertionRequestContext

  let size: CGSize
  let theme: SnapshotTheme
  let displayScale: Double
  let testName: String

  func generateRequests() async throws -> [any AssertionRequesting] {
    let request: any AssertionRequesting

    switch StrategySnapshotTrait.current {
      case .recursiveDescription:
        request = AssertionRequest(
          view: try await context.makeSnapshotView(),
          snapshotting: .recursiveDescription,
          snapshotDirectory: context.snapshotDirectory,
          testName: testName,
          fileID: context.fileID,
          filePath: context.filePath,
          line: context.line,
          column: context.column
        )

      case .image:
        #if canImport(UIKit)
        request = AssertionRequest(
          view: try await context.makeSnapshotView(),
          snapshotting: .image(
            size: size,
            traits: makeTraits()
          ),
          snapshotDirectory: context.snapshotDirectory,
          testName: testName,
          fileID: context.fileID,
          filePath: context.filePath,
          line: context.line,
          column: context.column
        )
        #elseif canImport(AppKit)
        request = AssertionRequest(
          view: try await context.makeSnapshotView(),
          snapshotting: .image(size: size),
          snapshotDirectory: context.snapshotDirectory,
          testName: testName,
          fileID: context.fileID,
          filePath: context.filePath,
          line: context.line,
          column: context.column
        )
        #endif
    }

    return [request]
  }

  #if canImport(UIKit)
  func makeTraits() -> UITraitCollection {
    if #available(iOS 17.0, *) {
      UITraitCollection {
        $0.displayScale = displayScale
        $0.userInterfaceStyle = theme
      }
    }
    else {
      UITraitCollection(traitsFrom: [
        .init(displayScale: displayScale),
        .init(userInterfaceStyle: theme),
      ])
    }
  }
  #endif
}
