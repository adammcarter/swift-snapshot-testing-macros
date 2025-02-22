import SwiftUI

@available(*, message: "This is an implementation detail. Do not initialise this type directly.")
@MainActor
public struct SnapshotGenerator<T: Sendable> {
  let displayName: String
  let traits: [SnapshotTrait]
  let configuration: SnapshotConfiguration<T>
  let makeValue: @MainActor (T) async throws -> SnapshotView
  let fileID: StaticString
  let filePath: StaticString
  let line: UInt
  let column: UInt

  public init(
    displayName: String,
    traits: [SnapshotTrait],
    configuration: SnapshotConfiguration<T>,
    makeValue: @escaping @MainActor (T) async throws -> SnapshotView,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    self.displayName = displayName
    self.traits = traits
    self.configuration = configuration
    self.makeValue = {
      SnapshotGenerator.makeModifiedView(
        from: try await makeValue($0),
        traits: traits
      )
    }
    self.fileID = fileID
    self.filePath = filePath
    self.line = line
    self.column = column
  }
}

// MARK: - Inits

// MARK: Public

/*
 Don't leak internal erased types and related protocols here, eg `SnapshotView`.

 Instead create an init for supported types explicitly as a public entry point
 */

#if canImport(SwiftUI)
extension SnapshotGenerator {
  public init<V: SwiftUI.View>(
    displayName: String,
    traits: [SnapshotTrait],
    configuration: SnapshotConfiguration<T>,
    makeValue: @escaping @MainActor (T) async throws -> V,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    self.displayName = displayName
    self.traits = traits
    self.configuration = configuration
    self.makeValue = {
      SnapshotGenerator.makeModifiedView(
        from: try await makeValue($0),
        traits: traits
      )
    }
    self.fileID = fileID
    self.filePath = filePath
    self.line = line
    self.column = column
  }
}
#endif

#if canImport(AppKit)
extension SnapshotGenerator {
  public init(
    displayName: String,
    traits: [SnapshotTrait],
    configuration: SnapshotConfiguration<T>,
    makeValue: @escaping @MainActor (T) async throws -> NSViewController,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    self.displayName = displayName
    self.traits = traits
    self.configuration = configuration
    self.makeValue = {
      SnapshotGenerator.makeModifiedView(
        from: (try await makeValue($0)).view,
        traits: traits
      )
    }
    self.fileID = fileID
    self.filePath = filePath
    self.line = line
    self.column = column
  }
}
#elseif canImport(UIKit)
extension SnapshotGenerator {
  public init(
    displayName: String,
    traits: [SnapshotTrait],
    configuration: SnapshotConfiguration<T>,
    makeValue: @escaping @MainActor (T) async throws -> UIViewController,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    self.displayName = displayName
    self.traits = traits
    self.configuration = configuration
    self.makeValue = {
      SnapshotGenerator.makeModifiedView(
        from: (try await makeValue($0)).view,
        traits: traits
      )
    }
    self.fileID = fileID
    self.filePath = filePath
    self.line = line
    self.column = column
  }
}
#endif
