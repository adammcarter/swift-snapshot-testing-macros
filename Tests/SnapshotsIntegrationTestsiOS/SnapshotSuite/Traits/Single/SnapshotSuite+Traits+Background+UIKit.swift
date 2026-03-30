#if canImport(UIKit)
import SnapshotTestingMacros
import Testing
import UIKit

extension SnapshotSuite.Traits.BackgroundColor {

  struct UIKit {}
}

extension SnapshotSuite.Traits.BackgroundColor.UIKit {

  @MainActor
  @Suite
  @SnapshotSuite
  struct DefaultWithoutOverride {

    @SnapshotTest
    func defaultBackground() -> UIView {
      makeLabel("\(#function) (clear)")
    }

    @SnapshotTest
    func explicitBackground() -> UIView {
      let label = makeLabel("\(#function) (systemBackground)")
      label.backgroundColor = .systemBackground

      return label
    }
  }

  @MainActor
  @Suite
  @SnapshotSuite(
    .backgroundColor(uiColor: .systemPink)
  )
  struct DefaultWithOverride {

    @SnapshotTest
    func defaultBackgroundOverridden() -> UIView {
      makeLabel("\(#function) (systemPink)")
    }

    @SnapshotTest
    func explicitBackgroundOverridden() -> UIView {
      let label = makeLabel("\(#function) (systemBackground)")
      label.backgroundColor = .systemBackground

      return label
    }
  }
}

extension SnapshotSuite.Traits.BackgroundColor.UIKit {

  @MainActor
  @Suite
  @SnapshotSuite(
    .backgroundColor(uiColor: .blue)
  )
  struct Blue {

    @SnapshotTest
    func blue() -> UIView {
      makeLabel(#function)
    }
  }
}

extension SnapshotSuite.Traits.BackgroundColor.UIKit {

  @MainActor
  @Suite
  @SnapshotSuite(
    .backgroundColor(uiColor: .clear)
  )
  struct Clear {

    @SnapshotTest
    func clear() -> UIView {
      makeLabel(#function)
    }
  }
}

extension SnapshotSuite.Traits.BackgroundColor.UIKit {

  @MainActor
  @Suite
  @SnapshotSuite
  struct ViewBackgroundColor {

    @SnapshotTest
    func viewBackgroundColor() -> UIView {
      let label = makeLabel("\(#function) (yellow)")
      label.backgroundColor = .yellow

      return label
    }

    @SnapshotTest(
      .backgroundColor(uiColor: .orange)
    )
    func viewBackgroundColorWithTrait() -> UIView {
      let label = makeLabel("\(#function) (yellow)")
      label.backgroundColor = .yellow

      return label
    }
  }
}

extension SnapshotSuite.Traits.BackgroundColor.UIKit {

  @MainActor
  @Suite
  @SnapshotSuite(
    .backgroundColor(uiColor: .gray)
  )
  struct Inheritance {

    @SnapshotTest(
      .backgroundColor(uiColor: .orange)
    )
    func inheritedFromTest() -> UIView {
      makeLabel("\(#function) (orange)")
    }

    @SnapshotTest
    func inheritedFromSuite() -> UIView {
      makeLabel("\(#function) (gray)")
    }
  }
}

extension SnapshotSuite.Traits.BackgroundColor.UIKit {

  @MainActor
  @Suite
  @SnapshotSuite(
    .backgroundColor(uiColor: .gray),
    .backgroundColor(uiColor: .green)
  )
  struct Multiple {

    @SnapshotTest(
      .backgroundColor(uiColor: .orange),
      .backgroundColor(uiColor: .purple)
    )
    func multipleTest() -> UIView {
      makeLabel("\(#function) (purple)")
    }

    @SnapshotTest
    func multipleInherited() -> UIView {
      makeLabel("\(#function) (green)")
    }
  }
}
#endif
