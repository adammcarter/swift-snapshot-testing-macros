import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest {

  @Suite
  struct ConfigurationValues {

    // MARK: - No display name

    @Suite
    @SnapshotSuite
    struct NoDisplayName {

      @SnapshotTest(
        configurationValues: [1, 2]
      )
      func testExplicitArray(value: Int) -> some View {
        Text("value: \(value)")
      }

      @SnapshotTest(
        configurationValues: makeConfigurations()
      )
      func testImplicitArray(value: Int) -> some View {
        Text("value: \(value)")
      }

      @SnapshotTest(
        configurationValues: makeConfigurations
      )
      func testHigherOrderFunction(value: Int) -> some View {
        Text("value: \(value)")
      }

      @SnapshotTest(
        configurationValues: configurations
      )
      func testDeclReference(value: Int) -> some View {
        Text("value: \(value)")
      }

      #if swift(>=6.1)
      // Closures inside macros have a compiler bug prior to Swift 6.1
      @SnapshotTest(
        configurationValues: { makeConfigurations() }
      )
      func testClosure(value: Int) -> some View {
        Text("value: \(value)")
      }
      #endif

      @SnapshotTest(
        configurationValues: ConfigurationGenerator.configurationValues
      )
      func testMemberAccess(value: Int) -> some View {
        Text("value: \(value)")
      }
    }

    // MARK: - Display name

    @Suite
    @SnapshotSuite
    struct WithDisplayName {

      @SnapshotTest(
        "Explicit array",
        configurationValues: [1, 2]
      )
      func testExplicitArray(value: Int) -> some View {
        Text("value: \(value)")
      }

      @SnapshotTest(
        "Implicit array",
        configurationValues: makeConfigurations()
      )
      func testImplicitArray(value: Int) -> some View {
        Text("value: \(value)")
      }

      @SnapshotTest(
        "Higher order function",
        configurationValues: makeConfigurations
      )
      func testHigherOrderFunction(value: Int) -> some View {
        Text("value: \(value)")
      }

      @SnapshotTest(
        "Decl reference",
        configurationValues: configurations
      )
      func testDeclReference(value: Int) -> some View {
        Text("value: \(value)")
      }

      #if swift(>=6.1)
      // Closures inside macros have a compiler bug prior to Swift 6.1
      @SnapshotTest(
        "Closure",
        configurationValues: { makeConfigurations() }
      )
      func testClosure(value: Int) -> some View {
        Text("value: \(value)")
      }
      #endif

      @SnapshotTest(
        "Member access",
        configurationValues: ConfigurationGenerator.configurationValues
      )
      func testMemberAccess(value: Int) -> some View {
        Text("value: \(value)")
      }
    }

    // MARK: - Strategy

    @Suite
    @SnapshotSuite
    struct Strategy {

      @SnapshotTest(
        ".image",
        .strategy(.image),
        configurationValues: configurations
      )
      func testImage(
        value: Int
      ) -> some View {
        Text(".image: \(value)")
      }

      @SnapshotTest(
        ".recursiveDescription",
        .strategy(.recursiveDescription),
        configurationValues: configurations
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

private func makeConfigurations() -> [Int] {
  [1, 2]
}

private struct ConfigurationGenerator {
  static var configurationValues: [Int] {
    makeConfigurations()
  }
}
