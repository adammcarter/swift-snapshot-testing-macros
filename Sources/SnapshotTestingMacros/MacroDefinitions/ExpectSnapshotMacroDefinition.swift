import SwiftUI

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View>(
  _ value: V,
  named: String? = nil
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot(
  _ value: SnapshotView,
  named: String? = nil
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot(
  _ value: SnapshotViewController,
  named: String? = nil
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View>(
  named: String? = nil,
  _ makeValue: @escaping () -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View>(
  named: String? = nil,
  _ makeValue: @escaping () throws -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View>(
  named: String? = nil,
  _ makeValue: @escaping () async -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View>(
  named: String? = nil,
  _ makeValue: @escaping () async throws -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  _ makeValue: @escaping (Argument) -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  _ makeValue: @escaping (ConfigurationValue) -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  _ makeValue: @escaping (A, B) -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  _ makeValue: @escaping (A, B, C) -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")
