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
      snapshotText(#function)
    }

    @SnapshotTest("space-separator")
    func `my test`() -> some View {
      snapshotText(#function)
    }

    @SnapshotTest("dash-separator")
    func `my-test`() -> some View {
      snapshotText(#function)
    }

    @SnapshotTest("repeated-dash-separator")
    func `my---test`() -> some View {
      snapshotText(#function)
    }

    @SnapshotTest("dot-separator")
    func `my.test`() -> some View {
      snapshotText(#function)
    }

    @SnapshotTest("slash-separator")
    func `my/test`() -> some View {
      snapshotText(#function)
    }

    @SnapshotTest("at-separator")
    func `my@test`() -> some View {
      snapshotText(#function)
    }

    @SnapshotTest
    func `123 start`() -> some View {
      snapshotText(#function)
    }

    @SnapshotTest
    func `_leading`() -> some View {
      snapshotText(#function)
    }

    @SnapshotTest
    func `trailing_`() -> some View {
      snapshotText(#function)
    }

    @SnapshotTest
    func `___`() -> some View {
      snapshotText(#function)
    }

    @SnapshotTest
    func `--a--`() -> some View {
      snapshotText(#function)
    }

    @SnapshotTest
    func `class`() -> some View {
      snapshotText(#function)
    }

    @SnapshotTest
    func `café`() -> some View {
      snapshotText(#function)
    }

    @SnapshotTest
    func `東京`() -> some View {
      snapshotText(#function)
    }
  }
}
// swiftlint:enable identifier_name
