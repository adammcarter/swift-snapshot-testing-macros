#if canImport(UIKit)
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotSuite.Traits.Theme.Inheritance {

  @Suite
  @SnapshotSuite(
    .sizes(.minimum, scale: 2.0),
    .theme(.light)
  )
  struct UIKit {

    @SnapshotTest(
      .theme(.dark)
    )
    func overridden() -> UILabel {
      let label = UILabel()
      label.text = "\(#function) (.dark)"
      return label
    }

    @SnapshotTest
    func inheritedFromSuite() -> UILabel {
      let label = UILabel()
      label.text = "\(#function) (.light)"
      return label
    }
  }
}
#endif
