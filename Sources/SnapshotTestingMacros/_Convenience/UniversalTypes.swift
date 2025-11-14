import SwiftUI

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
