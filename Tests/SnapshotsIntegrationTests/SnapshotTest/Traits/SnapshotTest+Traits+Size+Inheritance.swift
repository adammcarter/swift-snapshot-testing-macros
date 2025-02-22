import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotTest.Traits.Size {
  @Suite
  struct Inheritance {

    // MARK: - Singular device

    @Suite
    @SnapshotSuite(
      .sizes(.minimum)
    )
    struct SingularDevice {

      @SnapshotTest(
        .sizes(devices: .iPhoneX, fitting: .widthAndHeight)
      )
      func testSingularDeviceWidthAndHeight() -> some View {
        Text(".sizes(devices: .iPhoneX, fitting: .widthAndHeight)")
      }

      @SnapshotTest(
        .sizes(devices: .iPhoneX, fitting: .heightButMinimumWidth)
      )
      func testSingularDeviceHeightButMinimumWidth() -> some View {
        Text(".sizes(devices: .iPhoneX, fitting: .heightButMinimumWidth)")
      }

      @SnapshotTest(
        .sizes(devices: .iPhoneX, fitting: .widthButMinimumHeight)
      )
      func testSingularDeviceWidthButMinimumHeight() -> some View {
        Text(".sizes(devices: .iPhoneX, fitting: .widthButMinimumHeight)")
      }
    }

    // MARK: - Plural devices

    @Suite
    @SnapshotSuite(
      .sizes(.minimum)
    )
    struct PluralDevices {

      @SnapshotTest(
        .sizes(devices: .iPhoneX, .iPadPro11, fitting: .widthAndHeight)
      )
      func testPluralDevicesWidthAndHeight() -> some View {
        Text(".sizes(devices: .iPhoneX, .iPadPro11, fitting: .widthAndHeight)")
      }

      @SnapshotTest(
        .sizes(devices: .iPhoneX, .iPadPro11, fitting: .heightButMinimumWidth)
      )
      func testPluralDevicesHeightButMinimumWidth() -> some View {
        Text(".sizes(devices: .iPhoneX, .iPadPro11, fitting: .heightButMinimumWidth)")
      }

      @SnapshotTest(
        .sizes(devices: .iPhoneX, .iPadPro11, fitting: .widthButMinimumHeight)
      )
      func testPluralDevicesWidthButMinimumHeight() -> some View {
        Text(".sizes(devices: .iPhoneX, .iPadPro11, fitting: .widthButMinimumHeight)")
      }
    }

    // MARK: - Width and height

    @Suite
    @SnapshotSuite(
      .sizes(.minimum)
    )
    struct WidthAndHeight {

      @SnapshotTest(
        .sizes(width: 320, height: 480)
      )
      func testWidthAndHeight320x480() -> some View {
        Text(".sizes(width: 320, height: 480)")
      }
    }

    // MARK: - Width only

    @Suite
    @SnapshotSuite(
      .sizes(.minimum)
    )
    struct WidthOnly {

      @SnapshotTest(
        .sizes(width: 320)
      )
      func testWidth320() -> some View {
        Text(".sizes(width: 320)")
      }
    }

    // MARK: - Height only

    @Suite
    @SnapshotSuite(
      .sizes(.minimum)
    )
    struct HeightOnly {

      @SnapshotTest(
        .sizes(height: 480)
      )
      func testHeight480() -> some View {
        Text(".sizes(height: 480)")
      }
    }

    // MARK: - Minimum size

    @Suite
    @SnapshotSuite(
      .sizes(.minimum)
    )
    struct MinimumSize {

      @SnapshotTest(
        .sizes(.minimum)
      )
      func testMinimumSize() -> some View {
        Text(".sizes(.minimum)")
      }
    }

    // MARK: - Singular size

    @Suite
    @SnapshotSuite(
      .sizes(.minimum)
    )
    struct SingularSize {

      @SnapshotTest(
        .sizes(SizesSnapshotTrait.Size(width: 320, height: 480))
      )
      func testSingularSizeWidthHeight320x480() -> some View {
        Text(".sizes(SizesSnapshotTrait.Size(width: 320, height: 480))")
      }
    }

    // MARK: - Multiple sizes

    @Suite
    @SnapshotSuite(
      .sizes(.minimum)
    )
    struct MultipleSizes {

      @SnapshotTest(
        .sizes(
          SizesSnapshotTrait.Size(width: 320, height: 480),
          SizesSnapshotTrait.Size(width: 375, height: 667)
        )
      )
      func testMultipleSizesVariadic() -> some View {
        Text(".sizes(SizesSnapshotTrait.Size(width: 320, height: 480), SizesSnapshotTrait.Size(width: 375, height: 667))")
      }

      @SnapshotTest(
        .sizes([
          SizesSnapshotTrait.Size(width: 320, height: 480),
          SizesSnapshotTrait.Size(width: 375, height: 667),
        ])
      )
      func testMultipleSizesArray() -> some View {
        Text(".sizes([SizesSnapshotTrait.Size(width: 320, height: 480), SizesSnapshotTrait.Size(width: 375, height: 667)])")
      }
    }
  }
}
