// The Swift Programming Language
// https://docs.swift.org/swift-book

/// Marks a type as a suite of snapshot tests.
///
/// Use this macro to define a collection of snapshot tests. This is analogous to `@Suite` in Swift Testing.
///
/// The following default traits are applied unless overridden:
/// - Theme: `.theme(.all)` (Light and Dark mode)
/// - Size: `.sizes(.minimum)` (Intrinsic content size)
/// - Strategy: `.strategy(.image)` (Image comparison)
/// - Record: `.record(.missing)` (Record if missing)
/// - DiffTool: `.diffTool(.default)` (Default diff tool)
///
/// Example:
/// ```swift
/// @SnapshotSuite
/// struct MyViewTests {
///     @SnapshotTest
///     func myView() -> some View { ... }
/// }
/// ```
@available(*, deprecated, message: "Use native Swift Testing suites plus #expectSnapshot(...) instead.")
@attached(member, names: arbitrary)
public macro SnapshotSuite() = #externalMacro(module: "SnapshotsMacros", type: "SnapshotSuiteMacro")

/// Marks a type as a suite of snapshot tests with a display name.
///
/// The following default traits are applied unless overridden:
/// - Theme: `.theme(.all)` (Light and Dark mode)
/// - Size: `.sizes(.minimum)` (Intrinsic content size)
/// - Strategy: `.strategy(.image)` (Image comparison)
/// - Record: `.record(.missing)` (Record if missing)
/// - DiffTool: `.diffTool(.default)` (Default diff tool)
///
/// - Parameter displayName: The display name of the suite.
///
/// Example:
/// ```swift
/// @SnapshotSuite("My Display Name")
/// struct MySnapshotSuite {
///     // ...
/// }
/// ```
@available(*, deprecated, message: "Use native Swift Testing suites plus #expectSnapshot(...) instead.")
@attached(member, names: arbitrary)
public macro SnapshotSuite(
  _ displayName: String
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotSuiteMacro")

/// Marks a type as a suite of snapshot tests with traits.
///
/// The following default traits are applied unless overridden:
/// - Theme: `.theme(.all)` (Light and Dark mode)
/// - Size: `.sizes(.minimum)` (Intrinsic content size)
/// - Strategy: `.strategy(.image)` (Image comparison)
/// - Record: `.record(.missing)` (Record if missing)
/// - DiffTool: `.diffTool(.default)` (Default diff tool)
///
/// - Parameter traits: The traits to apply to the suite.
///
/// Example:
/// ```swift
/// @SnapshotSuite(.theme(.light), .sizes(devices: .iPhoneX))
/// struct MySnapshotSuite {
///     // ...
/// }
/// ```
@available(*, deprecated, message: "Use native Swift Testing suites plus #expectSnapshot(...) instead.")
@attached(member, names: arbitrary)
public macro SnapshotSuite(
  _ traits: any SnapshotSuiteTrait...
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotSuiteMacro")

/// Marks a type as a suite of snapshot tests with a display name and traits.
///
/// The following default traits are applied unless overridden:
/// - Theme: `.theme(.all)` (Light and Dark mode)
/// - Size: `.sizes(.minimum)` (Intrinsic content size)
/// - Strategy: `.strategy(.image)` (Image comparison)
/// - Record: `.record(.missing)` (Record if missing)
/// - DiffTool: `.diffTool(.default)` (Default diff tool)
///
/// - Parameters:
///   - displayName: The display name of the suite.
///   - traits: The traits to apply to the suite.
///
/// Example:
/// ```swift
/// @SnapshotSuite("My Display Name", .theme(.light), .sizes(devices: .iPhoneX))
/// struct MySnapshotSuite {
///     // ...
/// }
/// ```
@available(*, deprecated, message: "Use native Swift Testing suites plus #expectSnapshot(...) instead.")
@attached(member, names: arbitrary)
public macro SnapshotSuite(
  _ displayName: String?,
  _ traits: any SnapshotSuiteTrait...
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotSuiteMacro")
