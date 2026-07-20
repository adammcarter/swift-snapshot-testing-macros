import SwiftUI

// `canImport(UIKit)` alone is not a supported-platform check: watchOS (and other
// UIKit-flavoured platforms) import a reduced UIKit that lacks the controller and
// window types this library needs, so without this guard an unsupported consumer
// hits confusing "cannot find type" errors deep inside the package instead of a
// clear diagnostic. SPM's platforms list declares minimum versions only — it does
// not stop anyone building this package for other platforms.
#if os(watchOS) || os(tvOS) || os(visionOS)
#error("SnapshotTestingMacros supports iOS and macOS only.")
#endif

#if canImport(UIKit)
import UIKit

public typealias SnapshotColor = UIColor
public typealias SnapshotView = UIView
public typealias SnapshotViewController = UIViewController

typealias SnapshotHostingController = UIHostingController
typealias SnapshotTheme = UIUserInterfaceStyle
typealias SnapshotWindow = UIWindow
#elseif canImport(AppKit)
import AppKit

public typealias SnapshotColor = NSColor
public typealias SnapshotView = NSView
public typealias SnapshotViewController = NSViewController

typealias SnapshotHostingController = NSHostingController
typealias SnapshotTheme = NSAppearance
typealias SnapshotWindow = NSWindow
#else
#error("Unsupported platform")
#endif
