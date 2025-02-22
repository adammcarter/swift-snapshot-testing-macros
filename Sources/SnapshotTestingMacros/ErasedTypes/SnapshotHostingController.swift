#if canImport(SwiftUI)
import SwiftUI

#if canImport(AppKit)
typealias SnapshotHostingController = NSHostingController
#elseif canImport(UIKit)
typealias SnapshotHostingController = UIHostingController
#endif

#endif
