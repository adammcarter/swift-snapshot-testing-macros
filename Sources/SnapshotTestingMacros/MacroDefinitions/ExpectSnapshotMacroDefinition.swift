import SwiftUI

/*
 The public `#expectSnapshot` surface. Each declaration exists to accept a call shape; the
 expansion is identical for all of them and the real contract lives on the `__expectSnapshot`
 functions in `Assertion/expectSnapshot.swift`, which the expansion is re-type-checked against.

 Two deliberate asymmetries with those functions:

 - The SwiftUI builders carry `@ViewBuilder` here as well, so the surface describes itself —
   but the attribute only takes effect on the runtime function.

 - The SwiftUI builders are *not* marked `@MainActor` here, although the runtime functions are
   and the UIKit/AppKit declarations below are. Adding it makes every `@ViewBuilder` body
   ambiguous ("Ambiguous use of 'expectSnapshot(named:_:)'"): the SwiftUI and platform
   declarations then differ only in the closure's result type, and a result-builder body ties
   between them. The runtime functions break that tie with `@_disfavoredOverload`, which macro
   declarations cannot carry. The isolation is unaffected — it is enforced where the closure is
   actually consumed, and `ExpectSnapshot+SwiftUIIsolationCompileFixture` pins that from both a
   `@MainActor` and a nonisolated suite.
 */

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
  @ViewBuilder _ makeValue: @escaping () -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View>(
  named: String? = nil,
  @ViewBuilder _ makeValue: @escaping () throws -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View>(
  named: String? = nil,
  @ViewBuilder _ makeValue: @escaping () async -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View>(
  named: String? = nil,
  @ViewBuilder _ makeValue: @escaping () async throws -> V
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
  @ViewBuilder _ makeValue: @escaping (Argument) -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  @ViewBuilder _ makeValue: @escaping (Argument) throws -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  @ViewBuilder _ makeValue: @escaping (Argument) async -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  @ViewBuilder _ makeValue: @escaping (Argument) async throws -> V
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
  @ViewBuilder _ makeValue: @escaping (ConfigurationValue) -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  @ViewBuilder _ makeValue: @escaping (ConfigurationValue) throws -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  @ViewBuilder _ makeValue: @escaping (ConfigurationValue) async -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  @ViewBuilder _ makeValue: @escaping (ConfigurationValue) async throws -> V
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
  @ViewBuilder _ makeValue: @escaping (A, B) -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  @ViewBuilder _ makeValue: @escaping (A, B) throws -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  @ViewBuilder _ makeValue: @escaping (A, B) async -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  @ViewBuilder _ makeValue: @escaping (A, B) async throws -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  @ViewBuilder _ makeValue: @escaping (A, B, C) -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  @ViewBuilder _ makeValue: @escaping (A, B, C) throws -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  @ViewBuilder _ makeValue: @escaping (A, B, C) async -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")

@freestanding(expression)
public macro expectSnapshot<V: SwiftUI.View, A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  @ViewBuilder _ makeValue: @escaping (A, B, C) async throws -> V
) = #externalMacro(module: "SnapshotsMacros", type: "ExpectSnapshotMacro")
