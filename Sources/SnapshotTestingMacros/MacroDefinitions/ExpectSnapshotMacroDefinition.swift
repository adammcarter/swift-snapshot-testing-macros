import SwiftUI

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View>(
  _ value: V,
  named: String? = nil
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")
