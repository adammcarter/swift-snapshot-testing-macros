#if os(macOS)
import SnapshotTesting
@testable import SnapshotTestingMacros
import Testing

struct RecordSnapshotTraitTests {

  @Test
  func debugDescription() {
    let trait = RecordSnapshotTrait(record: .all)

    #expect(trait.debugDescription.starts(with: "record: "))
    #expect(trait.debugDescription.contains("all"))
  }

  @Test
  func provideScope() async throws {
    let trait = RecordSnapshotTrait(record: .all)

    // nil means "no trait set" so ambient pointfree configuration is inherited.
    #expect(RecordSnapshotTrait.current == nil)

    try await trait.provideScope {
      #expect(RecordSnapshotTrait.current == .all)
    }

    #expect(RecordSnapshotTrait.current == nil)
  }

  @Test
  func recordBool() {
    let trait = RecordSnapshotTrait.record(true)

    #expect(trait.record == .all)

    let traitFalse = RecordSnapshotTrait.record(false)

    #expect(traitFalse.record == .never)
  }

  @Test
  func recordKind() {
    let trait = RecordSnapshotTrait.record(.missing)

    #expect(trait.record == .missing)
  }

  @Test
  func recordProperty() {
    let trait = RecordSnapshotTrait.record

    #expect(trait.record == .all)
  }
}
#endif
