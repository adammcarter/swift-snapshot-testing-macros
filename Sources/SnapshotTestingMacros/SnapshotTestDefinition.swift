// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(peer, names: prefixed(__generator_container_)) public macro SnapshotTest() = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")

@attached(peer, names: prefixed(__generator_container_)) public macro SnapshotTest(
  _ displayName: String
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")

@attached(peer, names: prefixed(__generator_container_)) public macro SnapshotTest(
  _ traits: SnapshotTrait...
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")

@attached(peer, names: prefixed(__generator_container_)) public macro SnapshotTest(
  _ displayName: String,
  _ traits: SnapshotTrait...
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")

@attached(peer, names: prefixed(__generator_container_)) public macro SnapshotTest<T: Sendable>(
  _ traits: SnapshotTrait...,
  configurations: [SnapshotConfiguration<T>]
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")

@attached(peer, names: prefixed(__generator_container_)) public macro SnapshotTest<T: Sendable>(
  _ displayName: String?,
  _ traits: SnapshotTrait...,
  configurations: [SnapshotConfiguration<T>]
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")

@attached(peer, names: prefixed(__generator_container_)) public macro SnapshotTest<T: Sendable>(
  _ traits: SnapshotTrait...,
  configurations: () -> [SnapshotConfiguration<T>]
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")

@attached(peer, names: prefixed(__generator_container_)) public macro SnapshotTest<T: Sendable>(
  _ displayName: String?,
  _ traits: SnapshotTrait...,
  configurations: () -> [SnapshotConfiguration<T>]
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")

@attached(peer, names: prefixed(__generator_container_)) public macro SnapshotTest<C: Sendable>(
  _ traits: SnapshotTrait...,
  configurationValues: () -> [C]
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")

@attached(peer, names: prefixed(__generator_container_)) public macro SnapshotTest<C: Sendable>(
  _ displayName: String?,
  _ traits: SnapshotTrait...,
  configurationValues: () -> [C]
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")

@attached(peer, names: prefixed(__generator_container_)) public macro SnapshotTest<C>(
  _ traits: SnapshotTrait...,
  configurationValues: C
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")
where C: Collection & Sendable, C.Element: Sendable

@attached(peer, names: prefixed(__generator_container_)) public macro SnapshotTest<C>(
  _ displayName: String?,
  _ traits: SnapshotTrait...,
  configurationValues: C
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")
where C: Collection & Sendable, C.Element: Sendable
