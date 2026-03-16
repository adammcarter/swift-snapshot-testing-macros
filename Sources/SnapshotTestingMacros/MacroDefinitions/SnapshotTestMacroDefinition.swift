// The Swift Programming Language
// https://docs.swift.org/swift-book

/// Marks a function as a snapshot test.
///
/// Use this macro to define a snapshot test. This is analogous to `@Test` in Swift Testing.
///
/// Example:
/// ```swift
/// @SnapshotTest
/// func myView() -> some View {
///     Text("Hello, world!")
/// }
/// ```
@attached(peer, names: prefixed(__generator_container_))
public macro SnapshotTest() = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")

/// Marks a function as a snapshot test with a display name.
///
/// - Parameter displayName: The display name of the test.
@attached(peer, names: prefixed(__generator_container_))
public macro SnapshotTest(
  _ displayName: String
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")

/// Marks a function as a snapshot test with traits.
///
/// - Parameter traits: The traits to apply to the test.
@attached(peer, names: prefixed(__generator_container_))
public macro SnapshotTest(
  _ traits: any SnapshotTestTrait...
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")

/// Marks a function as a snapshot test with a display name and traits.
///
/// - Parameters:
///   - displayName: The display name of the test.
///   - traits: The traits to apply to the test.
@attached(peer, names: prefixed(__generator_container_))
public macro SnapshotTest(
  _ displayName: String,
  _ traits: any SnapshotTestTrait...
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")

/// Marks a function as a parameterized snapshot test with traits and configurations.
///
/// - Parameters:
///   - traits: The traits to apply to the test.
///   - configurations: An array of `SnapshotConfiguration`s defining the parameters for the test.
@attached(peer, names: prefixed(__generator_container_))
public macro SnapshotTest<T: Sendable>(
  _ traits: any SnapshotTestTrait...,
  configurations: [SnapshotConfiguration<T>]
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")

/// Marks a function as a parameterized snapshot test with a display name, traits, and configurations.
///
/// - Parameters:
///   - displayName: The display name of the test.
///   - traits: The traits to apply to the test.
///   - configurations: An array of `SnapshotConfiguration`s defining the parameters for the test.
@attached(peer, names: prefixed(__generator_container_))
public macro SnapshotTest<T: Sendable>(
  _ displayName: String?,
  _ traits: any SnapshotTestTrait...,
  configurations: [SnapshotConfiguration<T>]
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")

/// Marks a function as a parameterized snapshot test with traits and a configuration closure.
///
/// - Parameters:
///   - traits: The traits to apply to the test.
///   - configurations: A closure returning an array of `SnapshotConfiguration`s.
@attached(peer, names: prefixed(__generator_container_))
public macro SnapshotTest<T: Sendable>(
  _ traits: any SnapshotTestTrait...,
  configurations: () -> [SnapshotConfiguration<T>]
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")

/// Marks a function as a parameterized snapshot test with a display name, traits, and a configuration closure.
///
/// - Parameters:
///   - displayName: The display name of the test.
///   - traits: The traits to apply to the test.
///   - configurations: A closure returning an array of `SnapshotConfiguration`s.
@attached(peer, names: prefixed(__generator_container_))
public macro SnapshotTest<T: Sendable>(
  _ displayName: String?,
  _ traits: any SnapshotTestTrait...,
  configurations: () -> [SnapshotConfiguration<T>]
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")

/// Marks a function as a parameterized snapshot test with traits and configuration values closure.
///
/// - Parameters:
///   - traits: The traits to apply to the test.
///   - configurationValues: A closure returning an array of values to be used as configurations.
@attached(peer, names: prefixed(__generator_container_))
public macro SnapshotTest<C: Sendable>(
  _ traits: any SnapshotTestTrait...,
  configurationValues: () -> [C]
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")

/// Marks a function as a parameterized snapshot test with a display name, traits, and configuration values closure.
///
/// - Parameters:
///   - displayName: The display name of the test.
///   - traits: The traits to apply to the test.
///   - configurationValues: A closure returning an array of values to be used as configurations.
@attached(peer, names: prefixed(__generator_container_))
public macro SnapshotTest<C: Sendable>(
  _ displayName: String?,
  _ traits: any SnapshotTestTrait...,
  configurationValues: () -> [C]
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")

/// Marks a function as a parameterized snapshot test with traits and configuration values collection.
///
/// - Parameters:
///   - traits: The traits to apply to the test.
///   - configurationValues: A collection of values to be used as configurations.
@attached(peer, names: prefixed(__generator_container_))
public macro SnapshotTest<C>(
  _ traits: any SnapshotTestTrait...,
  configurationValues: C
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")
where C: Collection & Sendable, C.Element: Sendable

/// Marks a function as a parameterized snapshot test with a display name, traits, and configuration values collection.
///
/// - Parameters:
///   - displayName: The display name of the test.
///   - traits: The traits to apply to the test.
///   - configurationValues: A collection of values to be used as configurations.
@attached(peer, names: prefixed(__generator_container_))
public macro SnapshotTest<C>(
  _ displayName: String?,
  _ traits: any SnapshotTestTrait...,
  configurationValues: C
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotTestMacro")
where C: Collection & Sendable, C.Element: Sendable
