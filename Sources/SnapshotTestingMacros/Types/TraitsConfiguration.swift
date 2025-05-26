import CoreGraphics
import Foundation
import SnapshotTesting

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
struct TraitsConfiguration<ConfigurationValue: Sendable> {
  let record: Bool?
  let sizes: [SizesSnapshotTrait.Size]?
  let strategy: StrategySnapshotTrait.Strategy?
  let themes: [SnapshotTheme]
  
  let setUp: SnapshotSetUpTrait.SetUp?
  let setUpConfiguration: SnapshotConfigurationSetUpTrait<ConfigurationValue>.SetUp?

  init(traits: [SnapshotTrait]) throws(String) {
    self.record = makeRecord(traits: traits)
    self.sizes = makeSizes(traits: traits)
    self.strategy = makeStrategy(traits: traits)
    self.themes = try makeThemes(traits: traits)
    self.setUp = makeSetUp(traits: traits)
    self.setUpConfiguration = makeSetUpConfiguration(traits: traits)
  }
}

// MARK: - Support

// MARK: Set up

private func makeSetUp(
  traits: [SnapshotTrait]
) -> SnapshotSetUpTrait.SetUp? {
  traits
    .first(as: SnapshotSetUpTrait.self)?
    .setUp
}

private func makeSetUpConfiguration<T: Sendable>(
  traits: [SnapshotTrait]
) -> SnapshotConfigurationSetUpTrait<T>.SetUp? {
  traits
    .first(as: SnapshotConfigurationSetUpTrait<T>.self)?
    .setUp
}

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
