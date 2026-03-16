import SnapshotSupport
import Testing

/// A trait that sets the background color for a snapshot test or suite.
public struct BackgroundColorSnapshotTrait: SnapshotSuiteTrait, SnapshotTestTrait, __SnapshotTestScopingViewDecorator {
  let backgroundColor: SnapshotColor

  public var debugDescription: String {
    "backgroundColor: \(backgroundColor)"
  }

  public func updateConfiguration(_ configuration: inout __SnapshotViewDecoratorConfiguration) {
    configuration.backgroundColor = backgroundColor
  }
}
