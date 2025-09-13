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
  let sizes: [SizesSnapshotTrait.Size]?
  let strategy: StrategySnapshotTrait.Strategy?
  let themes: [SnapshotTheme]

  init(traits: [SnapshotTrait]) throws(String) {
    self.record = makeRecord(traits: traits)
    self.sizes = makeSizes(traits: traits)
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
private func makeSizes(traits: [SnapshotTrait]) -> [SizesSnapshotTrait.Size]? {
  traits
    .first(as: SizesSnapshotTrait.self)?
    .sizes
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
    case .all: [.light, .dark]
    case .dark: [.dark]
    case .light: [.light]
  }
}

#if canImport(UIKit)
@MainActor
extension SnapshotTheme {
  var testNameDescription: String {
    switch self {
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
  static let dark = SnapshotTheme(named: .darkAqua)!
  static let light = SnapshotTheme(named: .aqua)!

  var testNameDescription: String {
    switch self {
      case .dark: "dark"
      case .light: "light"
      default: "unknown"
    }
  }
}
#endif
