import Foundation

extension Constants {
  enum TypeName {
    static let snapshotConfiguration = "SnapshotConfiguration"
    static let snapshotConfigurationParser = "SnapshotConfigurationParser"
    static let snapshotViewGenerator = "SnapshotViewGenerator"
    static let snapshotViewGenerating = "SnapshotViewGenerating"
  }
}

extension MacroToken.TypeNameType {
  var snapshotConfiguration: MacroToken {
    .init(Constants.TypeName.snapshotConfiguration)
  }

  var snapshotViewGenerator: MacroToken {
    .init(Constants.TypeName.snapshotViewGenerator)
  }

  var snapshotViewGenerating: MacroToken {
    .init(Constants.TypeName.snapshotViewGenerating)
  }
}

extension MacroToken {
  static var TypeName: TypeNameType { .init() }

  struct TypeNameType: Sendable {}

  var namespaced: Self {
    .init("\(Constants.Namespace.snapshotTestingMacros).\(text)")
  }
}
