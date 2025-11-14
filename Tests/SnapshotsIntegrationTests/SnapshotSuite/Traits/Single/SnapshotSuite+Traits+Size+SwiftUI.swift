import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite.Traits.Sizes {

  @Suite
  struct SwiftUI {

    // MARK: - Singular device

    @Suite
    @SnapshotSuite(
      .sizes(devices: .iPhoneX, fitting: .widthAndHeight)
    )
    struct SingularDeviceWidthAndHeight {

      @SnapshotTest
      func testSingularDeviceWidthAndHeight() -> some View {
        Text(".sizes(devices: .iPhoneX, fitting: .widthAndHeight)")
      }
    }

    @Suite
    @SnapshotSuite(
      .sizes(devices: .iPhoneX, fitting: .heightButMinimumWidth)
    )
    struct SingularDeviceHeightButMinimumWidth {

      @SnapshotTest
      func testSingularDeviceHeightButMinimumWidth() -> some View {
        Text(".sizes(devices: .iPhoneX, fitting: .heightButMinimumWidth)")
      }
    }

    @Suite
    @SnapshotSuite(
      .sizes(devices: .iPhoneX, fitting: .widthButMinimumHeight)
    )
    struct SingularDeviceWidthButMinimumHeight {

      @SnapshotTest
      func testSingularDeviceWidthButMinimumHeight() -> some View {
        Text(".sizes(devices: .iPhoneX, fitting: .widthButMinimumHeight)")
      }
    }

    // MARK: - Plural devices

    @Suite
    @SnapshotSuite(
      .sizes(devices: .iPhoneX, .iPadPro11, fitting: .widthAndHeight)
    )
    struct PluralDevicesWidthAndHeight {

      @SnapshotTest
      func testPluralDevicesWidthAndHeight() -> some View {
        Text(".sizes(devices: .iPhoneX, .iPadPro11, fitting: .widthAndHeight)")
      }
    }

    @Suite
    @SnapshotSuite(
      .sizes(devices: .iPhoneX, .iPadPro11, fitting: .heightButMinimumWidth)
    )
    struct PluralDevicesHeightButMinimumWidth {

      @SnapshotTest
      func testPluralDevicesHeightButMinimumWidth() -> some View {
        Text(".sizes(devices: .iPhoneX, .iPadPro11, fitting: .heightButMinimumWidth)")
      }
    }

    @Suite
    @SnapshotSuite(
      .sizes(devices: .iPhoneX, .iPadPro11, fitting: .widthButMinimumHeight)
    )
    struct PluralDevicesWidthButMinimumHeight {

      @SnapshotTest
      func testPluralDevicesWidthButMinimumHeight() -> some View {
        Text(".sizes(devices: .iPhoneX, .iPadPro11, fitting: .widthButMinimumHeight)")
      }
    }

    // MARK: - Width and height

    @Suite
    @SnapshotSuite(
      .sizes(width: 320, height: 480)
    )
    struct Size320x480 {

      @SnapshotTest
      func testSize320x480() -> some View {
        Text(".sizes(width: 320, height: 480)")
      }
    }

    // MARK: - Width only

    @Suite
    @SnapshotSuite(
      .sizes(width: 320)
    )
    struct Width320 {

      @SnapshotTest
      func testWidth320() -> some View {
        Text(".sizes(width: 320)")
      }
    }

    // MARK: - Height only

    @Suite
    @SnapshotSuite(
      .sizes(height: 480)
    )
    struct Height480 {

      @SnapshotTest
      func testHeight480() -> some View {
        Text(".sizes(height: 480)")
      }
    }

    // MARK: - Minimum size

    @Suite
    @SnapshotSuite(
      .sizes(.minimum)
    )
    struct Minimum {

      @SnapshotTest
      func testMinimumSize() -> some View {
        Text(".sizes(.minimum)")
      }
    }

    // MARK: - Singular size

    @Suite
    @SnapshotSuite(
      .sizes(SizesSnapshotTrait.Size(width: 320, height: 480))
    )
    struct WidthHeight320x480 {

      @SnapshotTest
      func testWidthHeight320x480() -> some View {
        Text(".sizes(SizesSnapshotTrait.Size(width: 320, height: 480))")
      }
    }

    // MARK: - Multiple sizes

    @Suite
    @SnapshotSuite(
      .sizes(
        SizesSnapshotTrait.Size(width: 320, height: 480),
        SizesSnapshotTrait.Size(width: 375, height: 667)
      )
    )
    struct Variadic {

      @SnapshotTest
      func testMultipleSizesVariadic() -> some View {
        Text(".sizes(SizesSnapshotTrait.Size(width: 320, height: 480), SizesSnapshotTrait.Size(width: 375, height: 667))")
      }
    }

    @Suite
    @SnapshotSuite(
      .sizes([
        SizesSnapshotTrait.Size(width: 320, height: 480),
        SizesSnapshotTrait.Size(width: 375, height: 667),
      ])
    )
    struct Array {

      @SnapshotTest
      func testMultipleSizesArray() -> some View {
        Text(".sizes([SizesSnapshotTrait.Size(width: 320, height: 480), SizesSnapshotTrait.Size(width: 375, height: 667)])")
      }
    }
  }
}
