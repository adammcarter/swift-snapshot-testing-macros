import Foundation

extension Constants {
  enum Namespace {
    static let snapshotTestingMacros = "SnapshotTestingMacros"
  }
}

extension MacroToken.NamespaceType {
  var snapshotTestingMacros: MacroToken {
    .init(Constants.Namespace.snapshotTestingMacros)
  }
}

extension MacroToken {
  static var Namespace: NamespaceType { .init() }

  struct NamespaceType: Sendable {}
}
