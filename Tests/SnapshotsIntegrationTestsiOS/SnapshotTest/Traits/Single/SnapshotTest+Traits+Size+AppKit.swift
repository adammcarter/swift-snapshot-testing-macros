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
    @SnapshotSuite
    struct WidthAndHeight {

      @SnapshotTest(
        .sizes(width: 320, height: 480)
      )
      func testWidthAndHeight320x480() -> NSView {
        makeLabel(".sizes(width: 320, height: 480)")
      }
    }

    // MARK: - Width only

    @MainActor
    @Suite
    @SnapshotSuite
    struct WidthOnly {

      @SnapshotTest(
        .sizes(width: 320)
      )
      func testWidth320() -> NSView {
        makeLabel(".sizes(width: 320)")
      }
    }

    // MARK: - Height only

    @MainActor
    @Suite
    @SnapshotSuite
    struct HeightOnly {

      @SnapshotTest(
        .sizes(height: 480)
      )
      func testHeight480() -> NSView {
        makeLabel(".sizes(height: 480)")
      }
    }

    // MARK: - Minimum size

    @MainActor
    @Suite
    @SnapshotSuite
    struct MinimumSize {

      @SnapshotTest(
        .sizes(.minimum)
      )
      func testMinimumSize() -> NSView {
        makeLabel(".sizes(.minimum)")
      }
    }

    // MARK: - Singular size

    @MainActor
    @Suite
    @SnapshotSuite
    struct SingularSize {

      @SnapshotTest(
        .sizes(SizesSnapshotTrait.Size(width: 320, height: 480))
      )
      func testSingularSizeWidthHeight320x480() -> NSView {
        makeLabel(".sizes(SizesSnapshotTrait.Size(width: 320, height: 480))")
      }
    }

    // MARK: - Multiple sizes

    @MainActor
    @Suite
    @SnapshotSuite
    struct MultipleSizes {

      @SnapshotTest(
        .sizes(
          SizesSnapshotTrait.Size(width: 320, height: 480),
          SizesSnapshotTrait.Size(width: 375, height: 667)
        )
      )
      func testMultipleSizesVariadic() -> NSView {
        makeLabel(".sizes(SizesSnapshotTrait.Size(width: 320, height: 480), SizesSnapshotTrait.Size(width: 375, height: 667))")
      }

      @SnapshotTest(
        .sizes([
          SizesSnapshotTrait.Size(width: 320, height: 480),
          SizesSnapshotTrait.Size(width: 375, height: 667),
        ])
      )
      func testMultipleSizesArray() -> NSView {
        makeLabel(".sizes([SizesSnapshotTrait.Size(width: 320, height: 480), SizesSnapshotTrait.Size(width: 375, height: 667)])")
      }
    }
  }
}
#endif
