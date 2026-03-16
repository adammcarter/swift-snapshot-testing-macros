// The Swift Programming Language
// https://docs.swift.org/swift-book

/// Marks a type as a suite of snapshot tests.
///
/// Use this macro to define a collection of snapshot tests. This is analogous to `@Suite` in Swift Testing.
///
/// Example:
/// ```swift
/// @SnapshotSuite
/// struct MyViewTests {
///     @SnapshotTest
///     func myView() -> some View { ... }
/// }
/// ```
@attached(member, names: arbitrary)
public macro SnapshotSuite() = #externalMacro(module: "SnapshotsMacros", type: "SnapshotSuiteMacro")

/// Marks a type as a suite of snapshot tests with a display name.
///
/// - Parameter displayName: The display name of the suite.
@attached(member, names: arbitrary)
public macro SnapshotSuite(
  _ displayName: String
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotSuiteMacro")

/// Marks a type as a suite of snapshot tests with traits.
///
/// - Parameter traits: The traits to apply to the suite.
@attached(member, names: arbitrary)
public macro SnapshotSuite(
  _ traits: any SnapshotSuiteTrait...
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotSuiteMacro")

/// Marks a type as a suite of snapshot tests with a display name and traits.
///
/// - Parameters:
///   - displayName: The display name of the suite.
///   - traits: The traits to apply to the suite.
@attached(member, names: arbitrary)
public macro SnapshotSuite(
  _ displayName: String?,
  _ traits: any SnapshotSuiteTrait...
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotSuiteMacro")
