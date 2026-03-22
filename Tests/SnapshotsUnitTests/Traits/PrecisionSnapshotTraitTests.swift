#if os(macOS)
@testable import SnapshotTestingMacros
import Testing

struct PrecisionSnapshotTraitTests {

  @Test
  func debugDescription() {
    let trait = PrecisionSnapshotTrait(precision: 0.98)

    #expect(trait.debugDescription == "precision: 0.98")
  }

  @Test
  func provideScope() async throws {
    let trait = PrecisionSnapshotTrait.precision(0.98)

    #expect(PrecisionSnapshotTrait.current == 1)

    try await trait.provideScope {
      #expect(PrecisionSnapshotTrait.current == 0.98)
    }

    #expect(PrecisionSnapshotTrait.current == 1)
  }

  @Test
  func precisionConvenience() {
    let byPrecision = PrecisionSnapshotTrait.precision(0.8)
    let byTolerance = PrecisionSnapshotTrait.precision(tolerance: 0.2)

    #expect(byPrecision.precision == 0.8)
    #expect(byTolerance.precision == 0.8)
    #expect(PrecisionSnapshotTrait.precision(tolerance: -1).precision == 1)
    #expect(PrecisionSnapshotTrait.precision(tolerance: 2).precision == 0)
  }
}
#endif
