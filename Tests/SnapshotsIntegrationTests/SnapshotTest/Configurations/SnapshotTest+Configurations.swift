import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest {
  @Suite
  struct Configurations {

    // MARK: - No display name

    @Suite
    @SnapshotSuite
    struct NoDisplayName {

      @SnapshotTest(
        configurations: [
          SnapshotConfiguration(name: "Name 1", value: 1),
          SnapshotConfiguration(name: "Name 2", value: 2),
        ]
      )
      func testExplicitArray(value: Int) -> some View {
        Text("value: \(value)")
      }

      @SnapshotTest(
        configurations: [
          .init(name: "Name 1", value: 1),
          .init(name: "Name 2", value: 2),
        ]
      )
      func testDotInitArray(value: Int) -> some View {
        Text("value: \(value)")
      }

      @SnapshotTest(configurations: makeConfigurations())
      func testImplicitArray(value: Int) -> some View {
        Text("value: \(value)")
      }

      @SnapshotTest(configurations: makeConfigurations)
      func testHigherOrderFunction(value: Int) -> some View {
        Text("value: \(value)")
      }

      @SnapshotTest(configurations: configurations)
      func testDeclReference(value: Int) -> some View {
        Text("value: \(value)")
      }

      #if swift(>=6.1)
      // Closures inside macros have a compiler bug prior to Swift 6.1
      @SnapshotTest(configurations: { makeConfigurations() })
      func testClosure(value: Int) -> some View {
        Text("value: \(value)")
      }
      #endif

      @SnapshotTest(configurations: ConfigurationGenerator.configurations)
      func testMemberAccess(value: Int) -> some View {
        Text("value: \(value)")
      }

      @SnapshotTest(
        configurations: [
          SnapshotConfiguration(name: "Name 1", value: (1, "1")),
          SnapshotConfiguration(name: "Name 2", value: (2, "2")),
        ]
      )
      func testTwoValues(
        int: Int,
        string: String
      ) -> some View {
        Text("value: \(int), \(string)")
      }

      @SnapshotTest(
        configurations: [
          SnapshotConfiguration(name: "Name 1", value: (1, "1", 1.0)),
          SnapshotConfiguration(name: "Name 2", value: (2, "2", 2.0)),
        ]
      )
      func testThreeValues(
        int: Int,
        string: String,
        double: Double
      ) -> some View {
        Text("value: \(int), \(string), \(double)")
      }
    }

    // MARK: - Display name

    @Suite
    @SnapshotSuite
    struct WithDisplayName {

      @SnapshotTest(
        "Explicit array",
        configurations: [
          SnapshotConfiguration(name: "Name 1", value: 1),
          SnapshotConfiguration(name: "Name 2", value: 2),
        ]
      )
      func testExplicitArray(
        value: Int
      ) -> some View {
        Text("value: \(value)")
      }

      @SnapshotTest(
        ".init array",
        configurations: [
          .init(name: "Name 1", value: 1),
          .init(name: "Name 2", value: 2),
        ]
      )
      func testDotInitArray(value: Int) -> some View {
        Text("value: \(value)")
      }

      @SnapshotTest(
        "Implicit array",
        configurations: makeConfigurations()
      )
      func testImplicitArray(value: Int) -> some View {
        Text("value: \(value)")
      }

      @SnapshotTest(
        "Higher order function",
        configurations: makeConfigurations
      )
      func testHigherOrderFunction(value: Int) -> some View {
        Text("value: \(value)")
      }

      @SnapshotTest(
        "Decl reference",
        configurations: configurations
      )
      func testDeclReference(value: Int) -> some View {
        Text("value: \(value)")
      }

      #if swift(>=6.1)
      // Closures inside macros have a compiler bug prior to Swift 6.1
      @SnapshotTest(
        "Closure",
        configurations: { makeConfigurations() }
      )
      func testClosure(value: Int) -> some View {
        Text("value: \(value)")
      }
      #endif

      @SnapshotTest(
        "Member access",
        configurations: ConfigurationGenerator.configurations
      )
      func testMemberAccess(value: Int) -> some View {
        Text("value: \(value)")
      }

      @SnapshotTest(
        "Two values",
        configurations: [
          SnapshotConfiguration(name: "Name 1", value: (1, "1")),
          SnapshotConfiguration(name: "Name 2", value: (2, "2")),
        ]
      )
      func testTwoValues(
        int: Int,
        string: String
      ) -> some View {
        Text("value: \(int), \(string)")
      }

      @SnapshotTest(
        "Three values",
        configurations: [
          SnapshotConfiguration(name: "Name 1", value: (1, "1", 1.0)),
          SnapshotConfiguration(name: "Name 2", value: (2, "2", 2.0)),
        ]
      )
      func testThreeValues(
        int: Int,
        string: String,
        double: Double
      ) -> some View {
        Text("value: \(int), \(string), \(double)")
      }
    }

    // MARK: - Strategy

    @Suite
    @SnapshotSuite
    struct Strategy {

      @SnapshotTest(
        ".image",
        .strategy(.image),
        configurations: [
          SnapshotConfiguration(name: "Name 1", value: 1),
          SnapshotConfiguration(name: "Name 2", value: 2),
        ]
      )
      func testImage(
        value: Int
      ) -> some View {
        Text(".image: \(value)")
      }

      @SnapshotTest(
        ".recursiveDescription",
        .strategy(.recursiveDescription),
        configurations: [
          SnapshotConfiguration(name: "Name 1", value: 1),
          SnapshotConfiguration(name: "Name 2", value: 2),
        ]
      )
      func testRecursiveDescription(
        value: Int
      ) -> some View {
        Text(".recursiveDescription: \(value)")
      }
    }
  }
}

// MARK: - Support

private let configurations = makeConfigurations()

private func makeConfigurations() -> [SnapshotConfiguration<Int>] {
  [
    SnapshotConfiguration(name: "Name 1", value: 1),
    SnapshotConfiguration(name: "Name 2", value: 2),
  ]
}

private struct ConfigurationGenerator {
  static var configurations: [SnapshotConfiguration<Int>] {
    makeConfigurations()
  }
}
