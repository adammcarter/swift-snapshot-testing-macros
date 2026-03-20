#if canImport(UIKit)
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotSuite.Traits.Padding {

  @Suite
  struct UIKit {}
}

// MARK: - Padding with EdgeInsets

extension SnapshotSuite.Traits.Padding.UIKit {

  @Suite
  @SnapshotSuite(
    .sizes(.minimum, scale: 2.0),
    .padding(.init(top: 20, leading: 30, bottom: 10, trailing: 40))
  )
  struct EdgeInsets {

    @MainActor
    @SnapshotTest
    func testPaddingEdgeInsets() -> UIView {
      makeLabel(".padding(EdgeInsets(top: 20, leading: 30, bottom: 10, trailing: 40))")
    }
  }
}

// MARK: - Padding with edges and length

extension SnapshotSuite.Traits.Padding.UIKit {

  @Suite
  @SnapshotSuite(
    .sizes(.minimum, scale: 2.0),
    .padding(.all, 20)
  )
  struct All {

    @MainActor
    @SnapshotTest
    func testPaddingAll() -> UIView {
      makeLabel(".padding(.all, 20)")
    }
  }

  @Suite
  @SnapshotSuite(
    .sizes(.minimum, scale: 2.0),
    .padding(.horizontal, 15)
  )
  struct Horizontal {

    @MainActor
    @SnapshotTest
    func testPaddingHorizontal() -> UIView {
      makeLabel(".padding(.horizontal, 15)")
    }
  }

  @Suite
  @SnapshotSuite(
    .sizes(.minimum, scale: 2.0),
    .padding(.vertical, 30)
  )
  struct Vertical {

    @MainActor
    @SnapshotTest
    func testPaddingVertical() -> UIView {
      makeLabel(".padding(.vertical, 30)")
    }
  }
}

// MARK: - Padding with length only

extension SnapshotSuite.Traits.Padding.UIKit {

  @Suite
  @SnapshotSuite(
    .sizes(.minimum, scale: 2.0),
    .padding(30)
  )
  struct Length {

    @MainActor
    @SnapshotTest
    func testPaddingLength() -> UIView {
      makeLabel(".padding(30)")
    }
  }
}

// MARK: - Default padding

extension SnapshotSuite.Traits.Padding.UIKit {

  @Suite
  @SnapshotSuite(
    .sizes(.minimum, scale: 2.0),
    .padding
  )
  struct Default {

    @MainActor
    @SnapshotTest
    func testPaddingDefault() -> UIView {
      makeLabel(".padding")
    }
  }

  @Suite
  @SnapshotSuite(
    .sizes(.minimum, scale: 2.0),
    .padding()
  )
  struct DefaultParens {

    @MainActor
    @SnapshotTest
    func testPaddingDefaultParens() -> UIView {
      makeLabel(".padding()")
    }
  }
}
#endif
