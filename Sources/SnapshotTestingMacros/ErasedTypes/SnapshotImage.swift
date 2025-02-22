#if canImport(AppKit)
import AppKit

public typealias SnapshotImage = NSImage
#elseif canImport(UIKit)
import UIKit

public typealias SnapshotImage = UIImage
#endif
