import Foundation
import SnapshotSupport

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

@available(*, message: "This is an implementation detail. Do not use this type directly.")
// swiftlint:disable:next type_name
public struct __SnapshotViewDecoratorConfiguration: Sendable {
  @TaskLocal static var value: __SnapshotViewDecoratorConfiguration?

  var backgroundColor: SnapshotColor?
  var padding: NSDirectionalEdgeInsets?
}
