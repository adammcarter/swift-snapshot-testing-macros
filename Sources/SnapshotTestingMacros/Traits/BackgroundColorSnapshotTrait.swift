import SnapshotSupport
import Testing

public struct BackgroundColorSnapshotTrait: SnapshotSuiteTrait, SnapshotTestTrait, __SnapshotTestScopingViewDecorator {
  let backgroundColor: SnapshotColor

  public var debugDescription: String {
    "backgroundColor: \(backgroundColor)"
  }

  public func updateConfiguration(_ configuration: inout __SnapshotViewDecoratorConfiguration) {
    configuration.backgroundColor = backgroundColor
  }
}
