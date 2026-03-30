import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest.Traits.Padding {

  @Suite
  @SnapshotSuite(
    .padding(17)  // Randomly small or if this test breaks it could potentially make massive images and take a long time to do so
  )
  struct SwiftUI {

    // MARK: - Padding with EdgeInsets

    @SnapshotTest(
      .padding(.init(top: 20, leading: 30, bottom: 10, trailing: 40))
    )
    func testPaddingEdgeInsets() -> some View {
      snapshotText(".padding(EdgeInsets(top: 20, leading: 30, bottom: 10, trailing: 40))")
    }

    // MARK: - Padding with edges and length

    @SnapshotTest(
      .padding(.all, 20)
    )
    func testPaddingAll() -> some View {
      snapshotText(".padding(.all, 20)")
    }

    @SnapshotTest(
      .padding(.horizontal, 15)
    )
    func testPaddingHorizontal() -> some View {
      snapshotText(".padding(.horizontal, 15)")
    }

    @SnapshotTest(
      .padding(.vertical, 30)
    )
    func testPaddingVertical() -> some View {
      snapshotText(".padding(.vertical, 30)")
    }

    // MARK: - Padding with length only

    @SnapshotTest(
      .padding(30)
    )
    func testPaddingLength() -> some View {
      snapshotText(".padding(30)")
    }

    // MARK: - Default padding

    @SnapshotTest(
      .padding
    )
    func testPaddingDefault() -> some View {
      snapshotText(".padding")
    }

    @SnapshotTest(
      .padding()
    )
    func testPaddingDefaultParens() -> some View {
      snapshotText(".padding()")
    }

    // MARK: - Double padding

    @SnapshotTest(
      .padding,
      .padding
    )
    func testDoublePadding() -> some View {
      snapshotText(".padding, .padding")
    }
  }
}
