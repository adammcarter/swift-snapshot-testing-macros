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
    @SnapshotSuite(.sizes(.minimum, scale: 2.0))
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
    @SnapshotSuite(.sizes(.minimum, scale: 2.0))
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
    @SnapshotSuite(.sizes(.minimum, scale: 2.0))
    struct WidthAndHeight {

      @SnapshotTest(
        .sizes(width: 320, height: 480, scale: 2.0)
      )
      func testWidthAndHeight320x480() -> UIView {
        makeLabel(".sizes(width: 320, height: 480)")
      }
    }

    // MARK: - Width only

    @MainActor
    @Suite
    @SnapshotSuite(.sizes(.minimum, scale: 2.0))
    struct WidthOnly {

      @SnapshotTest(
        .sizes(width: 320, scale: 2.0)
      )
      func testWidth320() -> UIView {
        makeLabel(".sizes(width: 320)")
      }
    }

    // MARK: - Height only

    @MainActor
    @Suite
    @SnapshotSuite(.sizes(.minimum, scale: 2.0))
    struct HeightOnly {

      @SnapshotTest(
        .sizes(height: 480, scale: 2.0)
      )
      func testHeight480() -> UIView {
        makeLabel(".sizes(height: 480)")
      }
    }

    // MARK: - Minimum size

    @MainActor
    @Suite
    @SnapshotSuite(.sizes(.minimum, scale: 2.0))
    struct MinimumSize {

      @SnapshotTest(
        .sizes(.minimum, scale: 2.0)
      )
      func testMinimumSize() -> UIView {
        makeLabel(".sizes(.minimum)")
      }
    }

    // MARK: - Singular size

    @MainActor
    @Suite
    @SnapshotSuite(.sizes(.minimum, scale: 2.0))
    struct SingularSize {

      @SnapshotTest(
        .sizes(SizesSnapshotTrait.Size(width: 320, height: 480, scale: 2.0))
      )
      func testSingularSizeWidthHeight320x480() -> UIView {
        makeLabel(".sizes(SizesSnapshotTrait.Size(width: 320, height: 480))")
      }
    }

    // MARK: - Multiple sizes

    @MainActor
    @Suite
    @SnapshotSuite(.sizes(.minimum, scale: 2.0))
    struct MultipleSizes {

      @SnapshotTest(
        .sizes(
          SizesSnapshotTrait.Size(width: 320, height: 480, scale: 2.0),
          SizesSnapshotTrait.Size(width: 375, height: 667, scale: 2.0)
        )
      )
      func testMultipleSizesVariadic() -> UIView {
        makeLabel(".sizes(SizesSnapshotTrait.Size(width: 320, height: 480), SizesSnapshotTrait.Size(width: 375, height: 667))")
      }

      @SnapshotTest(
        .sizes([
          SizesSnapshotTrait.Size(width: 320, height: 480, scale: 2.0),
          SizesSnapshotTrait.Size(width: 375, height: 667, scale: 2.0),
        ])
      )
      func testMultipleSizesArray() -> UIView {
        makeLabel(".sizes([SizesSnapshotTrait.Size(width: 320, height: 480), SizesSnapshotTrait.Size(width: 375, height: 667)])")
      }
    }
  }
}
#endif
