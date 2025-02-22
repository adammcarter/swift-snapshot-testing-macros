import Foundation
import SwiftSyntax

extension Constants.Trait {
  var defaultValue: String? {
    switch self {
      case .backgroundColor,
        .bug,
        .disabled,
        .enabled,
        .padding,
        .timeLimit:
        nil

      case .tags,
        .record,
        .sizes,
        .strategy,
        .theme:
        if let defaultInnerValue {
          "\(prefix)(\(defaultInnerValue))"
        }
        else {
          nil
        }
    }
  }

  var defaultInnerValue: String? {
    switch self {
      case .backgroundColor,
        .bug,
        .disabled,
        .enabled,
        .padding,
        .tags,
        .timeLimit:
        nil

      case .record: "false"
      case .sizes: ".minimum"
      case .strategy: ".image"
      case .theme: ".all"
    }
  }

  /// Mark as true to transfer this along to `@Test` traits.
  var isSwiftTestingTrait: Bool {
    switch self {
      case .bug,
        .disabled,
        .enabled,
        .tags,
        .timeLimit:
        true

      case .backgroundColor,
        .padding,
        .record,
        .sizes,
        .strategy,
        .theme:
        false
    }
  }

  var prefix: String {
    ".\(rawValue)"
  }
}

extension Constants.Trait {
  /// Delegate for converting a raw input to something else before being passed to `@SnapshotSuite` / `@SnapshotTest`'s expanded code.
  static func mappingRawTraitToNewValue(_ rawTrait: String) -> String? {
    switch rawTrait {
      case ".record": ".record(true)"
      default: nil
    }
  }
}

extension Constants.Trait {
  init?(expression: ExprSyntax) {
    guard
      let trait = Constants.Trait.allCases.first(where: {
        expression.trimmedDescription.hasPrefix($0.prefix)
      })
    else {
      return nil
    }

    self = trait
  }
}
