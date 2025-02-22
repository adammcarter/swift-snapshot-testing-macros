#if canImport(AppKit)
import AppKit

typealias SnapshotViewController = NSViewController
#elseif canImport(UIKit)
import UIKit

typealias SnapshotViewController = UIViewController
#endif
