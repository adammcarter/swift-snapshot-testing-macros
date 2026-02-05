#if canImport(UIKit)
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotTest.Traits.Padding {

  @MainActor
  @Suite
  @SnapshotSuite
  struct UIKit {

    // MARK: - Padding with EdgeInsets

    @MainActor
    @SnapshotTest(
      .padding(.init(top: 20, leading: 30, bottom: 10, trailing: 40))
    )
    func testPaddingEdgeInsets() -> UIView {
      makeLabel(".padding(EdgeInsets(top: 20, leading: 30, bottom: 10, trailing: 40))")
    }

    // MARK: - Padding with edges and length

    @SnapshotTest(
      .padding(.all, 20)
    )
    func testPaddingAll() -> UIView {
      makeLabel(".padding(.all, 20)")
    }

    @SnapshotTest(
      .padding(.horizontal, 15)
    )
    func testPaddingHorizontal() -> UIView {
      makeLabel(".padding(.horizontal, 15)")
    }

    @SnapshotTest(
      .padding(.vertical, 30)
    )
    func testPaddingVertical() -> UIView {
      makeLabel(".padding(.vertical, 30)")
    }

    // MARK: - Padding with length only

    @SnapshotTest(
      .padding(30)
    )
    func testPaddingLength() -> UIView {
      makeLabel(".padding(30)")
    }

    // MARK: - Default padding

    @SnapshotTest(
      .padding
    )
    func testPaddingDefault() -> UIView {
      makeLabel(".padding")
    }

    @SnapshotTest(
      .padding()
    )
    func testPaddingDefaultParens() -> UIView {
      makeLabel(".padding()")
    }

    // MARK: - Double padding

    @SnapshotTest(
      .padding,
      .padding
    )
    func testDoublePadding() -> UIView {
      makeLabel(".padding, .padding")
    }
  }
}
#endif
