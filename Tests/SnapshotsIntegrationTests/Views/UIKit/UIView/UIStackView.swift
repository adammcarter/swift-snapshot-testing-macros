#if canImport(UIKit)
import SnapshotSupport
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotTest {

  @MainActor
  @Suite
  @SnapshotSuite
  struct _UIStackView {  // swiftlint:disable:this type_name

    @SnapshotTest
    func uiStackView() -> UIView {
      with(UIStackView()) {
        $0.axis = .vertical

        $0.addArrangedSubview(makeLabel("One"))
        $0.addArrangedSubview(makeLabel("Two"))
        $0.addArrangedSubview(makeLabel("Three"))
      }
    }
  }
}
#endif
