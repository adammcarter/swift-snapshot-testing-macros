import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest.Traits.Size {

  @Suite
  struct SwiftUI {

    // MARK: - Singular device

    @Suite
    @SnapshotSuite
    struct SingularDevice {

      @SnapshotTest(
        .sizes(devices: .iPhoneX, fitting: .widthAndHeight)
      )
      func testSingularDeviceWidthAndHeight() -> some View {
        snapshotText(".sizes(devices: .iPhoneX, fitting: .widthAndHeight)")
      }

      @SnapshotTest(
        .sizes(devices: .iPhoneX, fitting: .heightButMinimumWidth)
      )
      func testSingularDeviceHeightButMinimumWidth() -> some View {
        snapshotText(".sizes(devices: .iPhoneX, fitting: .heightButMinimumWidth)")
      }

      @SnapshotTest(
        .sizes(devices: .iPhoneX, fitting: .widthButMinimumHeight)
      )
      func testSingularDeviceWidthButMinimumHeight() -> some View {
        snapshotText(".sizes(devices: .iPhoneX, fitting: .widthButMinimumHeight)")
      }
    }

    // MARK: - Plural devices

    @Suite
    @SnapshotSuite
    struct PluralDevices {

      @SnapshotTest(
        .sizes(devices: .iPhoneX, .iPadPro11, fitting: .widthAndHeight)
      )
      func testPluralDevicesWidthAndHeight() -> some View {
        snapshotText(".sizes(devices: .iPhoneX, .iPadPro11, fitting: .widthAndHeight)")
      }

      @SnapshotTest(
        .sizes(devices: .iPhoneX, .iPadPro11, fitting: .heightButMinimumWidth)
      )
      func testPluralDevicesHeightButMinimumWidth() -> some View {
        snapshotText(".sizes(devices: .iPhoneX, .iPadPro11, fitting: .heightButMinimumWidth)")
      }

      @SnapshotTest(
        .sizes(devices: .iPhoneX, .iPadPro11, fitting: .widthButMinimumHeight)
      )
      func testPluralDevicesWidthButMinimumHeight() -> some View {
        snapshotText(".sizes(devices: .iPhoneX, .iPadPro11, fitting: .widthButMinimumHeight)")
      }
    }

    // MARK: - Width and height

    @Suite
    @SnapshotSuite
    struct WidthAndHeight {

      @SnapshotTest(
        .sizes(width: 320, height: 480)
      )
      func testWidthAndHeight320x480() -> some View {
        snapshotText(".sizes(width: 320, height: 480)")
      }
    }

    // MARK: - Width only

    @Suite
    @SnapshotSuite
    struct WidthOnly {

      @SnapshotTest(
        .sizes(width: 320)
      )
      func testWidth320() -> some View {
        snapshotText(".sizes(width: 320)")
      }
    }

    // MARK: - Height only

    @Suite
    @SnapshotSuite
    struct HeightOnly {

      @SnapshotTest(
        .sizes(height: 480)
      )
      func testHeight480() -> some View {
        snapshotText(".sizes(height: 480)")
      }
    }

    // MARK: - Minimum size

    @Suite
    @SnapshotSuite
    struct MinimumSize {

      @SnapshotTest(
        .sizes(.minimum)
      )
      func testMinimumSize() -> some View {
        snapshotText(".sizes(.minimum)")
      }
    }

    // MARK: - Singular size

    @Suite
    @SnapshotSuite
    struct SingularSize {

      @SnapshotTest(
        .sizes(SizesSnapshotTrait.Size(width: 320, height: 480))
      )
      func testSingularSizeWidthHeight320x480() -> some View {
        snapshotText(".sizes(SizesSnapshotTrait.Size(width: 320, height: 480))")
      }
    }

    // MARK: - Multiple sizes

    @Suite
    @SnapshotSuite
    struct MultipleSizes {

      @SnapshotTest(
        .sizes(
          SizesSnapshotTrait.Size(width: 320, height: 480),
          SizesSnapshotTrait.Size(width: 375, height: 667)
        )
      )
      func testMultipleSizesVariadic() -> some View {
        snapshotText(".sizes(SizesSnapshotTrait.Size(width: 320, height: 480), SizesSnapshotTrait.Size(width: 375, height: 667))")
      }

      @SnapshotTest(
        .sizes([
          SizesSnapshotTrait.Size(width: 320, height: 480),
          SizesSnapshotTrait.Size(width: 375, height: 667),
        ])
      )
      func testMultipleSizesArray() -> some View {
        snapshotText(".sizes([SizesSnapshotTrait.Size(width: 320, height: 480), SizesSnapshotTrait.Size(width: 375, height: 667)])")
      }
    }
  }
}
