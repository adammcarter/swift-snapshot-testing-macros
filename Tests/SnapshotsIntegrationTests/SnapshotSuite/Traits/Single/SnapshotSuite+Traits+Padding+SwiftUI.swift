import SnapshotTestingMacros
import SwiftUI
import Testing

extension SnapshotSuite.Traits.Padding {

  @Suite
  struct SwiftUI {}
}

// MARK: - Padding with EdgeInsets

extension SnapshotSuite.Traits.Padding.SwiftUI {

  @Suite
  @SnapshotSuite(
    .padding(.init(top: 20, leading: 30, bottom: 10, trailing: 40))
  )
  struct EdgeInsets {

    @SnapshotTest()
    func testPaddingEdgeInsets() -> some View {
      Text(".padding(EdgeInsets(top: 20, leading: 30, bottom: 10, trailing: 40))")
    }
  }
}

// MARK: - Padding with edges and length

extension SnapshotSuite.Traits.Padding.SwiftUI {

  @Suite
  @SnapshotSuite(
    .padding(.all, 20)
  )
  struct All {

    @SnapshotTest
    func testPaddingAll() -> some View {
      Text(".padding(.all, 20)")
    }
  }

  @Suite
  @SnapshotSuite(
    .padding(.horizontal, 15)
  )
  struct Horizontal {

    @SnapshotTest
    func testPaddingHorizontal() -> some View {
      Text(".padding(.horizontal, 15)")
    }
  }

  @Suite
  @SnapshotSuite(
    .padding(.vertical, 30)
  )
  struct Vertical {

    @SnapshotTest
    func testPaddingVertical() -> some View {
      Text(".padding(.vertical, 30)")
    }
  }
}

// MARK: - Padding with length only

extension SnapshotSuite.Traits.Padding.SwiftUI {

  @Suite
  @SnapshotSuite(
    .padding(30)
  )
  struct Length {

    @SnapshotTest
    func testPaddingLength() -> some View {
      Text(".padding(30)")
    }
  }
}

// MARK: - Default padding

extension SnapshotSuite.Traits.Padding.SwiftUI {

  @Suite
  @SnapshotSuite(
    .padding
  )
  struct Default {

    @SnapshotTest
    func testPaddingDefault() -> some View {
      Text(".padding")
    }
  }

  @Suite
  @SnapshotSuite(
    .padding()
  )
  struct DefaultParens {

    @SnapshotTest
    func testPaddingDefaultParens() -> some View {
      Text(".padding()")
    }
  }
}
