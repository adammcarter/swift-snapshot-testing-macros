import Foundation

extension Constants {
  enum AttributeName {
    static let available = "available"
    static let mainActor = "MainActor"

    static let test = "Test"

    static let snapshotSuite = "SnapshotSuite"
    static let snapshotTest = "SnapshotTest"
    static let suite = "Suite"
  }
}

extension MacroToken.AttributeNameType {
  var available: MacroToken {
    .init(Constants.AttributeName.available)
  }

  var mainActor: MacroToken {
    .init(Constants.AttributeName.mainActor)
  }

  var test: MacroToken {
    .init(Constants.AttributeName.test)
  }
}

extension MacroToken {
  static var AttributeName: AttributeNameType { .init() }

  struct AttributeNameType: Sendable {}
}
