#if canImport(AppKit)
import AppKit
import SnapshotTestingMacros
import Testing

extension SnapshotSuite.Traits.Sizes {

  @MainActor
  @Suite
  struct AppKit {

    // MARK: - Width and height

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(width: 320, height: 480, scale: 2.0)
    )
    struct Size320x480 {

      @SnapshotTest
      func testSize320x480() -> NSView {
        makeLabel(".sizes(width: 320, height: 480)")
      }
    }

    // MARK: - Width only

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(width: 320, scale: 2.0)
    )
    struct Width320 {

      @SnapshotTest
      func testWidth320() -> NSView {
        makeLabel(".sizes(width: 320)")
      }
    }

    // MARK: - Height only

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(height: 480, scale: 2.0)
    )
    struct Height480 {

      @SnapshotTest
      func testHeight480() -> NSView {
        makeLabel(".sizes(height: 480)")
      }
    }

    // MARK: - Minimum size

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(.minimum, scale: 2.0)
    )
    struct Minimum {

      @SnapshotTest
      func testMinimumSize() -> NSView {
        makeLabel(".sizes(.minimum)")
      }
    }

    // MARK: - Singular size

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(SizesSnapshotTrait.Size(width: 320, height: 480, scale: 2.0))
    )
    struct WidthHeight320x480 {

      @SnapshotTest
      func testWidthHeight320x480() -> NSView {
        makeLabel(".sizes(SizesSnapshotTrait.Size(width: 320, height: 480))")
      }
    }

    // MARK: - Multiple sizes

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(
        SizesSnapshotTrait.Size(width: 320, height: 480, scale: 2.0),
        SizesSnapshotTrait.Size(width: 375, height: 667, scale: 2.0)
      )
    )
    struct Variadic {

      @SnapshotTest
      func testMultipleSizesVariadic() -> NSView {
        makeLabel(".sizes(SizesSnapshotTrait.Size(width: 320, height: 480), SizesSnapshotTrait.Size(width: 375, height: 667))")
      }
    }

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes([
        SizesSnapshotTrait.Size(width: 320, height: 480, scale: 2.0),
        SizesSnapshotTrait.Size(width: 375, height: 667, scale: 2.0),
      ])
    )
    struct Array {

      @SnapshotTest
      func testMultipleSizesArray() -> NSView {
        makeLabel(".sizes([SizesSnapshotTrait.Size(width: 320, height: 480), SizesSnapshotTrait.Size(width: 375, height: 667)])")
      }
    }
  }
}
#endif
