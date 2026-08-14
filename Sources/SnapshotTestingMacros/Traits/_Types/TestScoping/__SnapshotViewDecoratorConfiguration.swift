import Foundation
import SnapshotSupport

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// This is an implementation detail of the snapshot trait machinery. Do not use this type
/// directly. It is `public` only for macro-generated code and is hidden from documentation.
@_documentation(visibility: private)
// swiftlint:disable:next type_name
public struct __SnapshotViewDecoratorConfiguration: Sendable {
  @TaskLocal
  static var value: __SnapshotViewDecoratorConfiguration?

  var backgroundColor: SnapshotColor?
  var padding: NSDirectionalEdgeInsets?
}
