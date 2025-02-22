#if canImport(AppKit)
import AppKit

public typealias SnapshotView = NSView
#elseif canImport(UIKit)
import UIKit

public typealias SnapshotView = UIView
#endif
