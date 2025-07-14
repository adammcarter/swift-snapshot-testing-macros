#if canImport(AppKit)
import AppKit

typealias SnapshotTheme = NSAppearance
#elseif canImport(UIKit)
import UIKit

typealias SnapshotTheme = UITraitCollection
#endif

// TODO: Create enum called SnapshotTheme to abstract out AppKit/UIKit so this can be used down the line to create a UITraitCollection with scaling
