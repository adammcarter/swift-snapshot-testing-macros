#if canImport(AppKit)
import AppKit

typealias SnapshotTheme = NSAppearance
#elseif canImport(UIKit)
import UIKit

typealias SnapshotTheme = UIUserInterfaceStyle
#endif
