import SnapshotTestingMacros
import SwiftUI
import Testing

// swiftlint:disable identifier_name
extension SnapshotTest {

  @Suite
  @SnapshotSuite
  struct EscapedIdentifiers {

    @SnapshotTest
    func myTest() -> some View {
      Text(#function)
    }

    @SnapshotTest("space-separator")
    func `my test`() -> some View {
      Text(#function)
    }

    @SnapshotTest("dash-separator")
    func `my-test`() -> some View {
      Text(#function)
    }

    @SnapshotTest("repeated-dash-separator")
    func `my---test`() -> some View {
      Text(#function)
    }

    @SnapshotTest("dot-separator")
    func `my.test`() -> some View {
      Text(#function)
    }

    @SnapshotTest("slash-separator")
    func `my/test`() -> some View {
      Text(#function)
    }

    @SnapshotTest("at-separator")
    func `my@test`() -> some View {
      Text(#function)
    }

    @SnapshotTest
    func `123 start`() -> some View {
      Text(#function)
    }

    @SnapshotTest
    func `_leading`() -> some View {
      Text(#function)
    }

    @SnapshotTest
    func `trailing_`() -> some View {
      Text(#function)
    }

    @SnapshotTest
    func `___`() -> some View {
      Text(#function)
    }

    @SnapshotTest
    func `--a--`() -> some View {
      Text(#function)
    }

    @SnapshotTest
    func `class`() -> some View {
      Text(#function)
    }

    @SnapshotTest
    func `café`() -> some View {
      Text(#function)
    }

    @SnapshotTest
    func `東京`() -> some View {
      Text(#function)
    }
  }
}
// swiftlint:enable identifier_name
