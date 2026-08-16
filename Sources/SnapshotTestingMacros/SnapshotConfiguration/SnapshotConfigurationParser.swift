import Foundation

/**
 Note: There's a bug prior to Swift 6.1 where the Swift Testing `arguments` parameter cannot take a closure.

 e.g. `arguments: { [SnapshotConfiguration()] }()` will cause a compiler error.

 The below wraps this error by just sending all of the arguments through this parser.

 `@Test` only invokes the array when it runs the test so we should still get the `laziness` of ad-hoc configurations even with arrays instead of closures.
 */

public struct SnapshotConfigurationParser {}

extension SnapshotConfigurationParser {
  public static func parse<T: Sendable>(_ arguments: [SnapshotConfiguration<T>]) -> [SnapshotConfiguration<T>] {
    arguments
  }

  public static func parse<T: Sendable>(_ arguments: () -> [SnapshotConfiguration<T>]) -> [SnapshotConfiguration<T>] {
    arguments()
  }
}

extension SnapshotConfigurationParser {
  public static func parse<T: Sendable>(_ arguments: [T]) -> [SnapshotConfiguration<T>] {
    arguments.map {
      SnapshotConfiguration(name: "\($0)", value: $0)
    }
  }

  public static func parse<T: Sendable>(_ arguments: () -> [T]) -> [SnapshotConfiguration<T>] {
    parse(arguments())
  }

  public static func parse<S: Sequence>(_ arguments: S) -> [SnapshotConfiguration<S.Element>]
  where S.Element: Sendable {
    arguments.map { SnapshotConfiguration(name: "\($0)", value: $0) }
  }

  public static func parse<S: Sequence>(_ arguments: () -> S) -> [SnapshotConfiguration<S.Element>]
  where S.Element: Sendable {
    parse(arguments())
  }
}

/*
 The `configurationValues:` macro overloads accept any `Collection & Sendable`, so the parser
 the generated code calls must accept any `Collection` too. Without these overloads, passing
 e.g. a range (`1...3`) or a `Set` compiles at the macro signature but fails to compile in the
 generated code with "no exact matches in call to static method 'parse'".

 `Array` arguments keep resolving to the more specialised `[T]` overloads above.
 */
extension SnapshotConfigurationParser {
  public static func parse<C: Collection>(_ arguments: C) -> [SnapshotConfiguration<C.Element>]
  where C.Element: Sendable {
    parse(Array(arguments))
  }

  public static func parse<C: Collection>(_ arguments: () -> C) -> [SnapshotConfiguration<C.Element>]
  where C.Element: Sendable {
    parse(arguments())
  }
}
