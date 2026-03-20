#if canImport(UIKit)
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotSuite.Traits.Sizes.Inheritance {

  @Suite
  @SnapshotSuite(
    .sizes(.minimum, scale: 2.0)
  )
  struct UIKit {

    @SnapshotTest(
      .sizes(devices: .iPhoneX, fitting: .widthAndHeight)
    )
    func overridden() -> UILabel {
      let label = UILabel()
      label.text = "\(#function) (.iPhoneX, .widthAndHeight)"
      return label
    }

    @SnapshotTest
    func inheritedFromSuite() -> UILabel {
      let label = UILabel()
      label.text = "\(#function) (.minimum)"
      return label
    }
  }
}
#endif
