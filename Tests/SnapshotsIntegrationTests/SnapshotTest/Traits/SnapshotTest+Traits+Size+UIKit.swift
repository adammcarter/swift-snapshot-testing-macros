#if canImport(UIKit)
import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest.Traits.Size {
  @Suite
  struct UIKit {

    // MARK: - Singular device

    @MainActor
    @Suite
    @SnapshotSuite
    struct SingularDevice {

      @SnapshotTest(
        .sizes(devices: .iPhoneX, fitting: .widthAndHeight)
      )
      func testSingularDeviceWidthAndHeight() -> UIView {
        makeLabel(".sizes(devices: .iPhoneX, fitting: .widthAndHeight)")
      }

      @SnapshotTest(
        .sizes(devices: .iPhoneX, fitting: .heightButMinimumWidth)
      )
      func testSingularDeviceHeightButMinimumWidth() -> UIView {
        makeLabel(".sizes(devices: .iPhoneX, fitting: .heightButMinimumWidth)")
      }

      @SnapshotTest(
        .sizes(devices: .iPhoneX, fitting: .widthButMinimumHeight)
      )
      func testSingularDeviceWidthButMinimumHeight() -> UIView {
        makeLabel(".sizes(devices: .iPhoneX, fitting: .widthButMinimumHeight)")
      }
    }

    // MARK: - Plural devices

    @MainActor
    @Suite
    @SnapshotSuite
    struct PluralDevices {

      @SnapshotTest(
        .sizes(devices: .iPhoneX, .iPadPro11, fitting: .widthAndHeight)
      )
      func testPluralDevicesWidthAndHeight() -> UIView {
        makeLabel(".sizes(devices: .iPhoneX, .iPadPro11, fitting: .widthAndHeight)")
      }

      @SnapshotTest(
        .sizes(devices: .iPhoneX, .iPadPro11, fitting: .heightButMinimumWidth)
      )
      func testPluralDevicesHeightButMinimumWidth() -> UIView {
        makeLabel(".sizes(devices: .iPhoneX, .iPadPro11, fitting: .heightButMinimumWidth)")
      }

      @SnapshotTest(
        .sizes(devices: .iPhoneX, .iPadPro11, fitting: .widthButMinimumHeight)
      )
      func testPluralDevicesWidthButMinimumHeight() -> UIView {
        makeLabel(".sizes(devices: .iPhoneX, .iPadPro11, fitting: .widthButMinimumHeight)")
      }
    }

    // MARK: - Width and height

    @MainActor
    @Suite
    @SnapshotSuite
    struct WidthAndHeight {

      @SnapshotTest(
        .sizes(width: 320, height: 480)
      )
      func testWidthAndHeight320x480() -> UIView {
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
      func testWidth320() -> UIView {
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
      func testHeight480() -> UIView {
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
      func testMinimumSize() -> UIView {
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
      func testSingularSizeWidthHeight320x480() -> UIView {
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
      func testMultipleSizesVariadic() -> UIView {
        makeLabel(".sizes(SizesSnapshotTrait.Size(width: 320, height: 480), SizesSnapshotTrait.Size(width: 375, height: 667))")
      }

      @SnapshotTest(
        .sizes([
          SizesSnapshotTrait.Size(width: 320, height: 480),
          SizesSnapshotTrait.Size(width: 375, height: 667),
        ])
      )
      func testMultipleSizesArray() -> UIView {
        makeLabel(".sizes([SizesSnapshotTrait.Size(width: 320, height: 480), SizesSnapshotTrait.Size(width: 375, height: 667)])")
      }
    }
  }
}
#endif
