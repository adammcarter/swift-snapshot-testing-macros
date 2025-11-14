#if canImport(UIKit)
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotSuite.Traits.Sizes {

  @Suite
  struct UIKit {

    // MARK: - Singular device

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(devices: .iPhoneX, fitting: .widthAndHeight)
    )
    struct SingularDeviceWidthAndHeight {

      @SnapshotTest
      func testSingularDeviceWidthAndHeight() -> UIView {
        makeLabel(".sizes(devices: .iPhoneX, fitting: .widthAndHeight)")
      }
    }

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(devices: .iPhoneX, fitting: .heightButMinimumWidth)
    )
    struct SingularDeviceHeightButMinimumWidth {

      @SnapshotTest
      func testSingularDeviceHeightButMinimumWidth() -> UIView {
        makeLabel(".sizes(devices: .iPhoneX, fitting: .heightButMinimumWidth)")
      }
    }

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(devices: .iPhoneX, fitting: .widthButMinimumHeight)
    )
    struct SingularDeviceWidthButMinimumHeight {

      @SnapshotTest
      func testSingularDeviceWidthButMinimumHeight() -> UIView {
        makeLabel(".sizes(devices: .iPhoneX, fitting: .widthButMinimumHeight)")
      }
    }

    // MARK: - Plural devices

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(devices: .iPhoneX, .iPadPro11, fitting: .widthAndHeight)
    )
    struct PluralDevicesWidthAndHeight {

      @SnapshotTest
      func testPluralDevicesWidthAndHeight() -> UIView {
        makeLabel(".sizes(devices: .iPhoneX, .iPadPro11, fitting: .widthAndHeight)")
      }
    }

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(devices: .iPhoneX, .iPadPro11, fitting: .heightButMinimumWidth)
    )
    struct PluralDevicesHeightButMinimumWidth {

      @SnapshotTest
      func testPluralDevicesHeightButMinimumWidth() -> UIView {
        makeLabel(".sizes(devices: .iPhoneX, .iPadPro11, fitting: .heightButMinimumWidth)")
      }
    }

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(devices: .iPhoneX, .iPadPro11, fitting: .widthButMinimumHeight)
    )
    struct PluralDevicesWidthButMinimumHeight {

      @SnapshotTest
      func testPluralDevicesWidthButMinimumHeight() -> UIView {
        makeLabel(".sizes(devices: .iPhoneX, .iPadPro11, fitting: .widthButMinimumHeight)")
      }
    }

    // MARK: - Width and height

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(width: 320, height: 480)
    )
    struct Size320x480 {

      @SnapshotTest
      func testSize320x480() -> UIView {
        makeLabel(".sizes(width: 320, height: 480)")
      }
    }

    // MARK: - Width only

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(width: 320)
    )
    struct Width320 {

      @SnapshotTest
      func testWidth320() -> UIView {
        makeLabel(".sizes(width: 320)")
      }
    }

    // MARK: - Height only

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(height: 480)
    )
    struct Height480 {

      @SnapshotTest
      func testHeight480() -> UIView {
        makeLabel(".sizes(height: 480)")
      }
    }

    // MARK: - Minimum size

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(.minimum)
    )
    struct Minimum {

      @SnapshotTest
      func testMinimumSize() -> UIView {
        makeLabel(".sizes(.minimum)")
      }
    }

    // MARK: - Singular size

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(SizesSnapshotTrait.Size(width: 320, height: 480))
    )
    struct WidthHeight320x480 {

      @SnapshotTest
      func testWidthHeight320x480() -> UIView {
        makeLabel(".sizes(SizesSnapshotTrait.Size(width: 320, height: 480))")
      }
    }

    // MARK: - Multiple sizes

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes(
        SizesSnapshotTrait.Size(width: 320, height: 480),
        SizesSnapshotTrait.Size(width: 375, height: 667)
      )
    )
    struct Variadic {

      @SnapshotTest
      func testMultipleSizesVariadic() -> UIView {
        makeLabel(".sizes(SizesSnapshotTrait.Size(width: 320, height: 480), SizesSnapshotTrait.Size(width: 375, height: 667))")
      }
    }

    @MainActor
    @Suite
    @SnapshotSuite(
      .sizes([
        SizesSnapshotTrait.Size(width: 320, height: 480),
        SizesSnapshotTrait.Size(width: 375, height: 667),
      ])
    )
    struct Array {

      @SnapshotTest
      func testMultipleSizesArray() -> UIView {
        makeLabel(".sizes([SizesSnapshotTrait.Size(width: 320, height: 480), SizesSnapshotTrait.Size(width: 375, height: 667)])")
      }
    }
  }
}
#endif
