import Testing

@testable import SnapshotTestingMacros

/// The size trait's `testNameDescription` is the only sizing input to the reference file name.
/// Explicit fixed dimensions must appear in the name so that multiple fixed sizes in one test
/// produce value-stable, order-independent reference names instead of relying purely on the
/// positional `.N` counter (which silently re-maps every reference when the sizes array is
/// reordered or edited).
struct SizesSnapshotTraitSizeNamingTests {
  @Test
  func fixedByFixedEmbedsBothDimensions() {
    let size = SizesSnapshotTrait.Size(width: .fixed(100), height: .fixed(200))

    #expect(size.testNameDescription == "fixed-100x200")
  }

  @Test
  func fixedWidthWithMinimumHeightEmbedsTheWidth() {
    let size = SizesSnapshotTrait.Size(width: .fixed(300), height: .minimum)

    #expect(size.testNameDescription == "min-height-w300")
  }

  @Test
  func minimumWidthWithFixedHeightEmbedsTheHeight() {
    let size = SizesSnapshotTrait.Size(width: .minimum, height: .fixed(200))

    #expect(size.testNameDescription == "min-width-h200")
  }

  /// The fully-minimum default is the name every committed reference in the wild was recorded
  /// under — it must never change.
  @Test
  func minimumByMinimumKeepsTheLegacyName() {
    let size = SizesSnapshotTrait.Size(width: .minimum, height: .minimum)

    #expect(size.testNameDescription == "min-size")
  }

  @Test
  func explicitScaleIsAppendedSoScaleVariantsDoNotCollide() {
    let scaled = SizesSnapshotTrait.Size(width: .fixed(100), height: .fixed(200), scale: 2)
    let minimumScaled = SizesSnapshotTrait.Size(width: .minimum, height: .minimum, scale: 3)

    #expect(scaled.testNameDescription == "fixed-100x200-2x")
    #expect(minimumScaled.testNameDescription == "min-size-3x")
  }

  @Test
  func fractionalValuesStayDeterministicAndFileNameSafe() {
    let size = SizesSnapshotTrait.Size(width: .fixed(100.5), height: .fixed(200), scale: 2.5)

    // Fractional dimensions/scale encode their decimal point as `p` (a word character) so the
    // `-` field delimiters can never be produced by a value — keeping distinct geometries from
    // colliding across the dimension/scale boundary.
    #expect(size.testNameDescription == "fixed-100p5x200-2p5x")
  }

  @Test
  func distinctFixedSizesInOneTestProduceDistinctNames() {
    let sizes = [
      SizesSnapshotTrait.Size(width: .fixed(300), height: .fixed(200)),
      SizesSnapshotTrait.Size(width: .fixed(400), height: .fixed(300)),
      SizesSnapshotTrait.Size(width: .fixed(300), height: .fixed(200), scale: 2),
    ]

    #expect(Set(sizes.map(\.testNameDescription)).count == sizes.count)
  }

  /// Regression: a fractional dimension and a fractional scale must not fold their decimal points
  /// into the `-` field delimiters and collide across the dimension/scale boundary. These two
  /// genuinely distinct geometries previously produced the identical name `fixed-100x2-5-5x`,
  /// reverting reference mapping to the order-dependent positional `.N` counter.
  @Test
  func fractionalDimensionAndFractionalScaleDoNotCollide() {
    let first = SizesSnapshotTrait.Size(width: .fixed(100), height: .fixed(2), scale: 5.5)
    let second = SizesSnapshotTrait.Size(width: .fixed(100), height: .fixed(2.5), scale: 5)

    #expect(first.testNameDescription != second.testNameDescription)
  }
}
