#if canImport(AppKit)
import AppKit
import SnapshotTestingMacros
import Testing

extension SnapshotTest.Traits.Size {

  @MainActor
  @Suite
  struct AppKit {

    // MARK: - Width and height

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0),
      .precision(0.98)
    )
    struct WidthAndHeight {

      @SnapshotTest(
        .sizes(width: 320, height: 480, scale: 2.0)
      )
      func testWidthAndHeight320x480() -> NSView {
        makeLabel(".sizes(width: 320, height: 480)")
      }
    }

    // MARK: - Width only

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0),
      .precision(0.98)
    )
    struct WidthOnly {

      @SnapshotTest(
        .sizes(width: 320, scale: 2.0)
      )
      func testWidth320() -> NSView {
        makeLabel(".sizes(width: 320)")
      }
    }

    // MARK: - Height only

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0),
      .precision(0.98)
    )
    struct HeightOnly {

      @SnapshotTest(
        .sizes(height: 480, scale: 2.0)
      )
      func testHeight480() -> NSView {
        makeLabel(".sizes(height: 480)")
      }
    }

    // MARK: - Minimum size

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0),
      .precision(0.98)
    )
    struct MinimumSize {

      @SnapshotTest(
        .sizes(.minimum, scale: 2.0)
      )
      func testMinimumSize() -> NSView {
        makeLabel(".sizes(.minimum)")
      }
    }

    // MARK: - Singular size

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0),
      .precision(0.98)
    )
    struct SingularSize {

      @SnapshotTest(
        .sizes(SizesSnapshotTrait.Size(width: 320, height: 480, scale: 2.0))
      )
      func testSingularSizeWidthHeight320x480() -> NSView {
        makeLabel(".sizes(SizesSnapshotTrait.Size(width: 320, height: 480))")
      }
    }

    // MARK: - Multiple sizes

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0),
      .precision(0.98)
    )
    struct MultipleSizes {

      @SnapshotTest(
        .sizes(
          SizesSnapshotTrait.Size(width: 320, height: 480, scale: 2.0),
          SizesSnapshotTrait.Size(width: 375, height: 667, scale: 2.0)
        )
      )
      func testMultipleSizesVariadic() -> NSView {
        makeLabel(".sizes(SizesSnapshotTrait.Size(width: 320, height: 480), SizesSnapshotTrait.Size(width: 375, height: 667))")
      }

      @SnapshotTest(
        .sizes([
          SizesSnapshotTrait.Size(width: 320, height: 480, scale: 2.0),
          SizesSnapshotTrait.Size(width: 375, height: 667, scale: 2.0),
        ])
      )
      func testMultipleSizesArray() -> NSView {
        makeLabel(".sizes([SizesSnapshotTrait.Size(width: 320, height: 480), SizesSnapshotTrait.Size(width: 375, height: 667)])")
      }
    }
  }
}
#endif
