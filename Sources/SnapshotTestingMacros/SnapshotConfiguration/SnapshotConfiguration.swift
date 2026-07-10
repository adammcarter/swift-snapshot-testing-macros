import Foundation

/// Names and carries a parameterised snapshot case for native Swift Testing.
///
/// Pass `SnapshotConfiguration` values to `@Test(arguments:)`, then use
/// `#expectSnapshot(configuration) { ... }` to build the snapshot value.
///
/// ```swift
/// @Suite(.theme(.all), .sizes(.minimum))
/// struct MySnapshots {
///   @Test(arguments: [
///     SnapshotConfiguration(name: "populated", value: "some_string"),
///     SnapshotConfiguration(name: "empty", value: ""),
///     SnapshotConfiguration(name: "nil", value: nil),
///   ])
///   func myView(configuration: SnapshotConfiguration<String?>) {
///     #expectSnapshot(configuration) { input in
///       Text("value: \(input ?? "<nil>")")
///     }
///   }
/// }
/// ```
///
/// Tuple-2 and tuple-3 values are unpacked into the builder closure parameters.
///
/// ```swift
/// @Suite(.theme(.all), .sizes(.minimum))
/// struct TupleSnapshots {
///   @Test(arguments: [
///     SnapshotConfiguration(name: "one", value: (1, "one")),
///     SnapshotConfiguration(name: "two", value: (2, "two")),
///   ])
///   func myView(configuration: SnapshotConfiguration<(Int, String)>) {
///     #expectSnapshot(configuration) { int, description in
///       Text("\(int.formatted()) == \(description)")
///     }
///   }
/// }
/// ```
///
/// When `name` is `nil` a name is derived from the value's description, normalized to a
/// file system-safe form (`"v1.0"` becomes `"v1-0"`). Tuple values are named per element and
/// joined with `-` (`(Layout.compact, UserState.loggedIn)` becomes `"compact-loggedIn"`), so
/// derived names never embed module or type qualification. Because normalization is lossy,
/// two distinct values in one `@Test(arguments:)` can derive the same name — e.g. `"v1.0"`
/// and `"v1 0"`; that collision is detected at runtime, recorded as an issue on the affected
/// test, and the colliding assertion is skipped rather than silently sharing the other
/// case's reference file. Give each configuration a distinct explicit `name` to resolve it.
public struct SnapshotConfiguration<T: Sendable>: Sendable {
  /// The name of the configuration.
  public let name: String?
  /// The value associated with the configuration.
  public let value: T

  /// Creates a new snapshot configuration.
  ///
  /// - Parameters:
  ///   - name: The name of the configuration.
  ///   - value: The value associated with the configuration.
  public init(name: String?, value: T) {
    self.name = name
    self.value = value
  }

  /// Convenience for passing a `value` of `Void`.
  public static var none: SnapshotConfiguration<Void> {
    .init(name: nil, value: ())
  }
}
