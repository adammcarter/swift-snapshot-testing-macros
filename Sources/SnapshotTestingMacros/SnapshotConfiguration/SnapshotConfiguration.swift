import Foundation

/// A type to define logical variants of snapshot tests that share common setup.
///
/// Similar to parameterized testing, configurations allow you to run the same test with varying inputs.
///
/// For example, you might use a snapshot configuration for an array of string values:
/// ```swift
/// @SnapshotSuite
/// struct MySnapshots {
///
///   @SnapshotTest(
///     configurations: [
///       SnapshotConfiguration(name: "Populated", value: "some_string"),
///       SnapshotConfiguration(name: "Empty", value: ""),
///       SnapshotConfiguration(name: "Nil", value: nil),
///     ]
///   )
///   func myView(input: String?) -> some View {
///     Text("value: \(input ?? "<nil>")")
///   }
/// }
/// ```
///
/// You can also pass more complex types to `value`, including tuples.
///
/// Tuples get unpacked in to arguments when the test function is invoked.
///
/// In the below the `value` has the tuple `(Int, String)` which is then unpacked in to the function arguments as `myView(int: Int, description: String)`:
/// ```swift
/// @SnapshotSuite
/// struct MySnapshots {
///
///   @SnapshotTest(
///     configurations: [
///       SnapshotConfiguration(name: "One", value: (1, "one")),
///       SnapshotConfiguration(name: "Two", value: (2, "two")),
///       SnapshotConfiguration(name: "Three", value: (3, "three")),
///     ]
///   )
///   func myView(int: Int, description: String) -> some View {
///     Text("\(int.formatted()) == \(description)")
///   }
/// }
/// ```
public struct SnapshotConfiguration<T: Sendable>: Sendable {
  public let name: String?
  public let value: T

  public init(name: String?, value: T) {
    self.name = name
    self.value = value
  }

  /// Convenience for passing a `value` of `Void`.
  public static var none: SnapshotConfiguration<Void> {
    .init(name: nil, value: ())
  }
}
