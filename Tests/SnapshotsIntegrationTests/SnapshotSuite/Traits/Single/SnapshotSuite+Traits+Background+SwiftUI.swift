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
      Text("\(#function) (clear)")
    }

    @SnapshotTest
    func explicitBackground() -> some View {
      Text("\(#function) (gray)")
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
      Text("\(#function) (pink)")
    }

    @SnapshotTest
    func explicitBackgroundOverridden() -> some View {
      Text("\(#function) (gray)")
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
      Text(#function)
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
      Text(#function)
    }
  }

}

extension SnapshotSuite.Traits.BackgroundColor.SwiftUI {

  @Suite
  @SnapshotSuite
  struct ViewBackgroundColor {

    @SnapshotTest
    func viewBackgroundColor() -> some View {
      Text("\(#function) (yellow)")
        .background(.yellow)
    }

    @SnapshotTest(
      .backgroundColor(.orange)
    )
    func viewBackgroundColorWithTrait() -> some View {
      Text("\(#function) (yellow)")
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
      Text("\(#function) (orange)")
    }

    @SnapshotTest
    func inheritedFromSuite() -> some View {
      Text("\(#function) (gray)")
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
      Text("\(#function) (purple)")
    }

    @SnapshotTest
    func multipleInherited() -> some View {
      Text("\(#function) (green)")
    }
  }
}
#endif
