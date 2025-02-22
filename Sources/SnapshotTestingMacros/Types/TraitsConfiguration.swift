import CoreGraphics
import Foundation
import SnapshotTesting

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
struct TraitsConfiguration {
  let record: Bool?
  let sizes: [(SizesSnapshotTrait.Size, CGSize)]
  let strategy: StrategySnapshotTrait.Strategy?
  let themes: [SnapshotTheme]

  init(
    traits: [SnapshotTrait],
    view: SnapshotView
  ) throws(String) {
    self.record = makeRecord(traits: traits)
    self.sizes = try makeSizes(traits: traits, view: view)
    self.strategy = makeStrategy(traits: traits)
    self.themes = try makeThemes(traits: traits)
  }
}

// MARK: - Support

// MARK: Record

private func makeRecord(
  traits: [SnapshotTrait]
) -> Bool? {
  traits
    .first(as: RecordSnapshotTrait.self)?
    .record
}

// MARK: Sizes

@MainActor
private func makeSizes(
  traits: [SnapshotTrait],
  view: SnapshotView
) throws(String) -> [(SizesSnapshotTrait.Size, CGSize)] {
  let sizeTrait = traits.first(as: SizesSnapshotTrait.self)

  do {
    return try sizeTrait?
      .sizes
      .compactMap { traitSize -> (SizesSnapshotTrait.Size, CGSize) in
        let absoluteSize = traitSize.absoluteSize(for: view)

        guard absoluteSize.width > 0 else {
          throw "0 width for snapshot"
        }

        guard absoluteSize.height > 0 else {
          throw "0 height for snapshot"
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
      case let (.fixed(width), .fixed(height)):
        .init(width: width, height: height)

      case (.minimum, .minimum):
        view.compressedSizeWhenConstrained()

      case let (.fixed(width), .minimum):
        view.compressedSizeWhenConstrained(toWidth: width)

      case let (.minimum, .fixed(height)):
        view.compressedSizeWhenConstrained(toHeight: height)
    }
  }
}

// MARK: Strategy

@MainActor
private func makeStrategy(traits: [SnapshotTrait]) -> StrategySnapshotTrait.Strategy? {
  traits.first(as: StrategySnapshotTrait.self)?.strategy
}

// MARK: Themes

@MainActor
private func makeThemes(
  traits: [SnapshotTrait]
) throws(String) -> [SnapshotTheme] {
  guard
    let themeTrait = traits.first(as: ThemeSnapshotTrait.self)
  else {
    throw "Missing theme for snapshot"
  }

  return switch themeTrait.theme {
    case .all: [.lightTraits, .darkTraits]
    case .dark: [.darkTraits]
    case .light: [.lightTraits]
  }
}

#if canImport(UIKit)
@MainActor
extension SnapshotTheme {
  static let darkTraits = SnapshotTheme(userInterfaceStyle: .dark)
  static let lightTraits = SnapshotTheme(userInterfaceStyle: .light)

  var testNameDescription: String {
    switch userInterfaceStyle {
      case .dark: "dark"
      case .light: "light"
      case .unspecified: "unspecified"
      @unknown default: "unknown"
    }
  }
}
#elseif canImport(AppKit)
@MainActor
extension SnapshotTheme {
  static let darkTraits = SnapshotTheme(named: .darkAqua)!
  static let lightTraits = SnapshotTheme(named: .aqua)!

  var testNameDescription: String {
    switch self {
      case .darkTraits: "dark"
      case .lightTraits: "light"
      default: "unknown"
    }
  }
}
#endif
