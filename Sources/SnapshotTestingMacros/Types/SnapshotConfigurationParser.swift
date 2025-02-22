import Foundation

/*

 Note: There's a bug prior to Swift 6.1 where Swift Testing `arguments` cannot take a closure

 e.g. `arguments: { [SnapshotConfiguration()] }()`

 So use an array for now.

 '@Test' only invokes the array when it runs the test so we should still get the `laziness` of ad-hoc configurations even with arrays instead of closures.

 */

public struct SnapshotConfigurationParser {

  // MARK: SnapshotConfiguration

  public static func parse<T: Sendable>(
    _ arguments: [SnapshotConfiguration<T>]
  ) -> [SnapshotConfiguration<T>] {
    arguments
  }

  public static func parse<T: Sendable>(
    _ arguments: () -> [SnapshotConfiguration<T>]
  ) -> [SnapshotConfiguration<T>] {
    arguments()
  }

  // MARK: Values

  public static func parse<T: Sendable>(
    _ arguments: [T]
  ) -> [SnapshotConfiguration<T>] {
    arguments.map {
      SnapshotConfiguration(name: "\($0)", value: $0)
    }
  }

  public static func parse<T: Sendable>(
    _ arguments: () -> [T]
  ) -> [SnapshotConfiguration<T>] {
    parse(arguments())
  }
}
