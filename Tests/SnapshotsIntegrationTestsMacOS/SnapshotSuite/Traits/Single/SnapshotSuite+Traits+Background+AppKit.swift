#if canImport(AppKit)
import AppKit
import SnapshotTestingMacros
import Testing

extension SnapshotSuite.Traits.BackgroundColor {

  struct AppKit {}
}

extension SnapshotSuite.Traits.BackgroundColor.AppKit {

  @MainActor
  @Suite
  @SnapshotSuite(.sizes(.minimum, scale: 2.0))
  struct DefaultWithoutOverride {

    @SnapshotTest
    func defaultBackground() -> NSView {
      makeLabel("\(#function) (clear)")
    }

    @SnapshotTest
    func explicitBackground() -> NSView {
      let label = makeLabel("\(#function) (windowBackgroundColor)")
      label.wantsLayer = true
      label.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

      return label
    }
  }

  @MainActor
  @Suite
  @SnapshotSuite(
    .sizes(.minimum, scale: 2.0),
    .backgroundColor(nsColor: .systemPink)
  )
  struct DefaultWithOverride {

    @SnapshotTest
    func defaultBackgroundOverridden() -> NSView {
      makeLabel("\(#function) (systemPink)")
    }

    @SnapshotTest
    func explicitBackgroundOverridden() -> NSView {
      let label = makeLabel("\(#function) (windowBackgroundColor)")
      label.wantsLayer = true
      label.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

      return label
    }
  }
}

extension SnapshotSuite.Traits.BackgroundColor.AppKit {

  @MainActor
  @Suite
  @SnapshotSuite(
    .sizes(.minimum, scale: 2.0),
    .backgroundColor(nsColor: .blue)
  )
  struct Blue {

    @SnapshotTest
    func blue() -> NSView {
      makeLabel(#function)
    }
  }
}

extension SnapshotSuite.Traits.BackgroundColor.AppKit {

  @MainActor
  @Suite
  @SnapshotSuite(
    .sizes(.minimum, scale: 2.0),
    .backgroundColor(nsColor: .clear)
  )
  struct Clear {

    @SnapshotTest
    func clear() -> NSView {
      makeLabel(#function)
    }
  }
}

extension SnapshotSuite.Traits.BackgroundColor.AppKit {

  @MainActor
  @Suite
  @SnapshotSuite(.sizes(.minimum, scale: 2.0))
  struct ViewBackgroundColor {

    @SnapshotTest
    func viewBackgroundColor() -> NSView {
      let label = makeLabel("\(#function) (yellow)")
      label.wantsLayer = true
      label.layer?.backgroundColor = NSColor.yellow.cgColor

      return label
    }

    @SnapshotTest(
      .backgroundColor(nsColor: .orange)
    )
    func viewBackgroundColorWithTrait() -> NSView {
      let label = makeLabel("\(#function) (yellow)")
      label.wantsLayer = true
      label.layer?.backgroundColor = NSColor.yellow.cgColor

      return label
    }
  }
}

extension SnapshotSuite.Traits.BackgroundColor.AppKit {

  @MainActor
  @Suite
  @SnapshotSuite(
    .sizes(.minimum, scale: 2.0),
    .backgroundColor(nsColor: .gray)
  )
  struct Inheritance {

    @SnapshotTest(
      .backgroundColor(nsColor: .orange)
    )
    func inheritedFromTest() -> NSView {
      makeLabel("\(#function) (orange)")
    }

    @SnapshotTest
    func inheritedFromSuite() -> NSView {
      makeLabel("\(#function) (gray)")
    }
  }
}

extension SnapshotSuite.Traits.BackgroundColor.AppKit {

  @MainActor
  @Suite
  @SnapshotSuite(
    .sizes(.minimum, scale: 2.0),
    .backgroundColor(nsColor: .gray),
    .backgroundColor(nsColor: .green)
  )
  struct Multiple {

    @SnapshotTest(
      .backgroundColor(nsColor: .orange),
      .backgroundColor(nsColor: .purple)
    )
    func multipleTest() -> NSView {
      makeLabel("\(#function) (purple)")
    }

    @SnapshotTest
    func multipleInherited() -> NSView {
      makeLabel("\(#function) (green)")
    }
  }
}
#endif
