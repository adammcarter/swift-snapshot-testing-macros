#if os(macOS)
import AppKit
import CoreGraphics
import Testing

@testable import SnapshotTestingMacros

@MainActor
enum AssertionRequestGeneratorTestSupport {
  static func makeContext(
    name: String = "base",
    configurationName: String? = nil,
    traitConfiguration: AssertionRequestContext.TraitConfiguration,
    makeSnapshotView: @escaping @MainActor () throws -> SnapshotViewController = makeSnapshotView
  ) -> AssertionRequestContext {
    AssertionRequestContext(
      name: name,
      configurationName: configurationName,
      traitConfiguration: traitConfiguration,
      makeSnapshotView: makeSnapshotView,
      snapshotDirectory: "/tmp",
      fileID: "fileID",
      filePath: "filePath",
      line: 1,
      column: 1
    )
  }

  static func makeTraitSize(
    width: SizesSnapshotTrait.Length = .fixed(120),
    height: SizesSnapshotTrait.Length = .fixed(80),
    scale: Double? = nil,
    displayName: String = "display_name_1",
    debugDescription: String = "debug_description_1",
    testNameDescription: String = "test_name_description_1"
  ) -> SizesSnapshotTrait.Size {
    .init(
      width: width,
      height: height,
      scale: scale,
      displayName: displayName,
      debugDescription: debugDescription,
      testNameDescription: testNameDescription
    )
  }

  static func assertCommonMetadata(_ request: any AssertionRequesting) {
    #expect(request.snapshotDirectory == "/tmp")
    #expect(request.fileID.description == "fileID")
    #expect(request.filePath.description == "filePath")
    #expect(request.line == 1)
    #expect(request.column == 1)
  }

  static func makeSnapshotView() throws -> SnapshotViewController {
    let controller = SnapshotViewController()
    controller.view = SnapshotView(frame: .init(x: 0, y: 0, width: 200, height: 200))
    return controller
  }
}
#endif
