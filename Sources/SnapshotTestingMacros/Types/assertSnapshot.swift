import Foundation
import SnapshotTesting
import SwiftUI
import XCTest

#if canImport(Testing)
import Testing
#endif

@available(*, message: "This is an implementation detail. Do not call this function directly.")
@MainActor
public func assertSnapshot<ConfigurationValue: Sendable>(
  generator: SnapshotGenerator<ConfigurationValue>
) async throws {
  do {
    let unpackedTraits = try TraitsConfiguration(traits: generator.traits)

    let view = try await generator.makeValue(
      generator.configuration.value
    )

    try assertSnapshots(
      testNamePrefix: generator.displayName,
      configurationName: generator.configuration.name,
      view: view,
      themes: unpackedTraits.themes,
      sizes: makeSizes(sizes: unpackedTraits.sizes, view: view),
      strategy: unpackedTraits.strategy,
      record: unpackedTraits.record,
      fileID: generator.fileID,
      filePath: generator.filePath,
      line: generator.line,
      column: generator.column
    )
  }
  catch {
    let traitsDescription = generator
      .traits
      .map(\.debugDescription)
      .filter { $0.isEmpty == false }

    recordIssue(
      error: error,
      message: "named: \(generator.displayName), traits: \(traitsDescription)",
      fileID: generator.fileID,
      filePath: generator.filePath,
      line: generator.line,
      column: generator.column
    )
  }
}

// MARK: - Support

// MARK: Assertion

@MainActor
private func assertSnapshots(
  testNamePrefix: String,
  configurationName: String?,
  view: SnapshotView,
  themes: [SnapshotTheme],
  sizes: [(SizesSnapshotTrait.Size, CGSize)],
  strategy: StrategySnapshotTrait.Strategy?,
  record: Bool?,
  fileID: StaticString,
  filePath: StaticString,
  line: UInt,
  column: UInt
) throws {
  for (sizeTrait, size) in sizes {
    let displayScale = makeDisplayScale(sizeTrait: sizeTrait)

    for theme in themes {
      /*
       The following, in order, joined by an underscore.
       Any subcomponent should replace spaces with a hyphen.

       test display name, configuration name, size trait, theme trait
       */

      let testName = [
        testNamePrefix,
        sizeTrait.testNameDescription,
        theme.testNameDescription,
      ]
      .joined(separator: "_")

      assertSnapshot(
        testName: testName,
        folderName: configurationName,
        view: view,
        size: size,
        theme: theme,
        displayScale: displayScale,
        strategy: strategy,
        record: record,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
    }
  }
}

@MainActor
private func makeDisplayScale(sizeTrait: SizesSnapshotTrait.Size) -> Double {
  let inheritedSclae: Double? = {
    #if canImport(UIKit)
    UIWindow().traitCollection.displayScale
    #elseif canImport(AppKit)
    NSScreen.main.flatMap {
      Double($0.backingScaleFactor)
    }
    #endif
  }()

  return sizeTrait.scale ?? inheritedSclae ?? 1.0
}

@MainActor
private func assertSnapshot(
  testName: String,
  folderName: String?,
  view: SnapshotView,
  size: CGSize,
  theme: SnapshotTheme,
  displayScale: Double,
  strategy: StrategySnapshotTrait.Strategy?,
  record: Bool?,
  fileID: StaticString,
  filePath: StaticString,
  line: UInt,
  column: UInt
) {
  switch strategy {
    case .recursiveDescription:
      assertSnapshot(
        of: view,
        as: .recursiveDescription,
        record: record,
        folderName: folderName,
        fileID: fileID,
        file: filePath,
        testName: testName,
        line: line,
        column: column
      )

    case .image, .none:
      assertSnapshot(
        of: view,
        as: makeImageStrategy(
          size: size,
          theme: theme,
          displayScale: displayScale
        ),
        record: record,
        folderName: folderName,
        fileID: fileID,
        file: filePath,
        testName: testName,
        line: line,
        column: column
      )
  }
}

@MainActor
private func makeImageStrategy(
  size: CGSize,
  theme: SnapshotTheme,
  displayScale: Double
) -> Snapshotting<SnapshotView, SnapshotImage> {
  #if canImport(AppKit)
  .image(size: size)
  #elseif canImport(UIKit)
  let traitCollection = UITraitCollection(traitsFrom: [
    .init(displayScale: displayScale),
    .init(userInterfaceStyle: theme),
  ])

  return .image(
    size: size,
    traits: traitCollection
  )
  #else
  #error("Unsupported platform")
  #endif
}

@MainActor
private func assertSnapshot<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, Format>,
  record recording: Bool? = nil,
  folderName: String?,
  timeout: TimeInterval = 5,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: String = #function,
  line: UInt = #line,
  column: UInt = #column
) {
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
      $0.appendPathComponent("\(folderName) configuration", isDirectory: true)
    }
  }

  let message = SnapshotTesting.verifySnapshot(
    of: try value(),
    as: snapshotting,
    named: nil,
    record: recording,
    snapshotDirectory: snapshotDirectory.path,
    timeout: timeout,
    fileID: fileID,
    file: filePath,
    testName: testName,
    line: line,
    column: column
  )

  guard let message else { return }

  recordIssue(
    message: message,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}

// MARK: Sizes

@MainActor
private func makeSizes(
  sizes: [SizesSnapshotTrait.Size]?,
  view: SnapshotView
) throws(String) -> [(SizesSnapshotTrait.Size, CGSize)] {
  do {
    return try sizes?
      .compactMap { traitSize -> (SizesSnapshotTrait.Size, CGSize) in
        let absoluteSize = traitSize.absoluteSize(for: view)

        guard absoluteSize != .zero else {
          throw "size is zero for snapshot"
        }

        guard absoluteSize.width > 0 else {
          throw "zero width for snapshot"
        }

        guard absoluteSize.height > 0 else {
          throw "zero height for snapshot"
        }

        return (traitSize, absoluteSize)
      } ?? []
  }
  catch let error as String {
    throw error
  }
  catch {
    fatalError("Caught unexpected error: \(error.localizedDescription)")
  }
}

@MainActor
extension SizesSnapshotTrait.Size {
  fileprivate func absoluteSize(for view: SnapshotView) -> CGSize {
    switch (width, height) {
      case let (
        .fixed(width),
        .fixed(height)
      ):
        .init(width: width, height: height)

      case (
        .minimum,
        .minimum
      ):
        view.compressedSizeWhenConstrained()

      case let (
        .fixed(width),
        .minimum
      ):
        view.compressedSizeWhenConstrained(toWidth: width)

      case let (
        .minimum,
        .fixed(height)
      ):
        view.compressedSizeWhenConstrained(toHeight: height)
    }
  }
}

// MARK: - Errors

extension String: @retroactive Error {}

private func recordIssue(
  error: Error? = nil,
  message: @autoclosure () -> String,
  fileID: StaticString,
  filePath: StaticString,
  line: UInt,
  column: UInt
) {
#if canImport(Testing)
  let comment = Comment(rawValue: message())
  let sourceLocation = SourceLocation(
    fileID: fileID.description,
    filePath: filePath.description,
    line: Int(line),
    column: Int(column)
  )

  if Test.current != nil {
    if let error {
      Issue.record(
        error,
        comment,
        sourceLocation: sourceLocation
      )
    }
    else {
      Issue.record(
        comment,
        sourceLocation: sourceLocation
      )
    }
  }
  else {
    Issue.record(
      comment,
      sourceLocation: sourceLocation
    )
  }
#else
  XCTFail(message(), file: filePath, line: line)
#endif
}

// MARK: - Debugging

#if canImport(AppKit)
extension NSView {
  fileprivate var image: NSImage? {
    let mySize = self.bounds.size
    let imgSize = NSSize(width: mySize.width, height: mySize.height)

    guard let bir = self.bitmapImageRepForCachingDisplay(in: self.bounds) else { return nil }
    bir.size = imgSize
    self.cacheDisplay(in: self.bounds, to: bir)

    let image = NSImage(size: imgSize)
    image.addRepresentation(bir)
    return image
  }
}
#endif
