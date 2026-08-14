import SwiftUI

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View>(
  _ value: V,
  named: String? = nil
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot(
  _ value: @autoclosure @escaping @MainActor () -> SnapshotView,
  named: String? = nil
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot(
  _ value: @autoclosure @escaping @MainActor () -> SnapshotViewController,
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
public macro expectSnapshot(
  named: String? = nil,
  _ makeValue: @escaping @MainActor () -> SnapshotView
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot(
  named: String? = nil,
  _ makeValue: @escaping @MainActor () -> SnapshotViewController
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot(
  named: String? = nil,
  _ makeValue: @escaping @MainActor () throws -> SnapshotView
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot(
  named: String? = nil,
  _ makeValue: @escaping @MainActor () throws -> SnapshotViewController
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot(
  named: String? = nil,
  _ makeValue: @escaping @MainActor () async -> SnapshotView
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot(
  named: String? = nil,
  _ makeValue: @escaping @MainActor () async -> SnapshotViewController
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot(
  named: String? = nil,
  _ makeValue: @escaping @MainActor () async throws -> SnapshotView
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot(
  named: String? = nil,
  _ makeValue: @escaping @MainActor () async throws -> SnapshotViewController
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  _ makeValue: @escaping (Argument) -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  _ makeValue: @escaping (Argument) throws -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  _ makeValue: @escaping (Argument) async -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  _ makeValue: @escaping (Argument) async throws -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (Argument) -> SnapshotView
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (Argument) -> SnapshotViewController
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (Argument) throws -> SnapshotView
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (Argument) throws -> SnapshotViewController
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (Argument) async -> SnapshotView
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (Argument) async -> SnapshotViewController
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (Argument) async throws -> SnapshotView
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (Argument) async throws -> SnapshotViewController
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  _ makeValue: @escaping (ConfigurationValue) -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  _ makeValue: @escaping (ConfigurationValue) throws -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  _ makeValue: @escaping (ConfigurationValue) async -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  _ makeValue: @escaping (ConfigurationValue) async throws -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (ConfigurationValue) -> SnapshotView
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (ConfigurationValue) -> SnapshotViewController
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (ConfigurationValue) throws -> SnapshotView
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (ConfigurationValue) throws -> SnapshotViewController
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (ConfigurationValue) async -> SnapshotView
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (ConfigurationValue) async -> SnapshotViewController
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (ConfigurationValue) async throws -> SnapshotView
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (ConfigurationValue) async throws -> SnapshotViewController
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (A, B) -> SnapshotView
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (A, B) -> SnapshotViewController
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (A, B) throws -> SnapshotView
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (A, B) throws -> SnapshotViewController
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (A, B) async -> SnapshotView
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (A, B) async -> SnapshotViewController
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (A, B) async throws -> SnapshotView
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (A, B) async throws -> SnapshotViewController
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (A, B, C) -> SnapshotView
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (A, B, C) -> SnapshotViewController
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (A, B, C) throws -> SnapshotView
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (A, B, C) throws -> SnapshotViewController
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (A, B, C) async -> SnapshotView
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (A, B, C) async -> SnapshotViewController
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (A, B, C) async throws -> SnapshotView
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  _ makeValue: @escaping @MainActor (A, B, C) async throws -> SnapshotViewController
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  _ makeValue: @escaping (A, B) -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  _ makeValue: @escaping (A, B) throws -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  _ makeValue: @escaping (A, B) async -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  _ makeValue: @escaping (A, B) async throws -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  _ makeValue: @escaping (A, B, C) -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  _ makeValue: @escaping (A, B, C) throws -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  _ makeValue: @escaping (A, B, C) async -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  _ makeValue: @escaping (A, B, C) async throws -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")
