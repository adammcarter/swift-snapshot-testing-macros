#if canImport(SwiftUI)
import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite.Traits.BackgroundColor {

  struct SwiftUI {}
}

extension SnapshotSuite.Traits.BackgroundColor.SwiftUI {

  @Suite
  @SnapshotSuite
  struct DefaultWithoutOverride {

    @SnapshotTest
    func defaultBackground() -> some View {
      snapshotText("\(#function) (clear)")
    }

    @SnapshotTest
    func explicitBackground() -> some View {
      snapshotText("\(#function) (gray)")
        .foregroundStyle(.primary)
        .background(.gray)
    }
  }

  @Suite
  @SnapshotSuite(
    .backgroundColor(.pink)
  )
  struct DefaultWithOverride {

    @SnapshotTest
    func defaultBackgroundOverridden() -> some View {
      snapshotText("\(#function) (pink)")
    }

    @SnapshotTest
    func explicitBackgroundOverridden() -> some View {
      snapshotText("\(#function) (gray)")
        .background(.gray)
        .foregroundStyle(.primary)
    }
  }
}

extension SnapshotSuite.Traits.BackgroundColor.SwiftUI {

  @Suite
  @SnapshotSuite(
    .backgroundColor(.blue)
  )
  struct Blue {

    @SnapshotTest()
    func blue() -> some View {
      snapshotText(#function)
    }
  }

}

extension SnapshotSuite.Traits.BackgroundColor.SwiftUI {

  @Suite
  @SnapshotSuite(
    .backgroundColor(.clear)
  )
  struct Clear {

    @SnapshotTest
    func clear() -> some View {
      snapshotText(#function)
    }
  }

}

extension SnapshotSuite.Traits.BackgroundColor.SwiftUI {

  @Suite
  @SnapshotSuite
  struct ViewBackgroundColor {

    @SnapshotTest
    func viewBackgroundColor() -> some View {
      snapshotText("\(#function) (yellow)")
        .background(.yellow)
    }

    @SnapshotTest(
      .backgroundColor(.orange)
    )
    func viewBackgroundColorWithTrait() -> some View {
      snapshotText("\(#function) (yellow)")
        .background(.yellow)
    }
  }

}

extension SnapshotSuite.Traits.BackgroundColor.SwiftUI {

  @Suite
  @SnapshotSuite(
    .backgroundColor(.gray)
  )
  struct Inheritance {

    @SnapshotTest(
      .backgroundColor(.orange)
    )
    func overridden() -> some View {
      snapshotText("\(#function) (orange)")
    }

    @SnapshotTest
    func inheritedFromSuite() -> some View {
      snapshotText("\(#function) (gray)")
    }
  }

}

extension SnapshotSuite.Traits.BackgroundColor.SwiftUI {

  @Suite
  @SnapshotSuite(
    .backgroundColor(.gray),
    .backgroundColor(.green)
  )
  struct Multiple {

    @SnapshotTest(
      .backgroundColor(.orange),
      .backgroundColor(.purple)
    )
    func multipleTest() -> some View {
      snapshotText("\(#function) (purple)")
    }

    @SnapshotTest
    func multipleInherited() -> some View {
      snapshotText("\(#function) (green)")
    }
  }
}
#endif
