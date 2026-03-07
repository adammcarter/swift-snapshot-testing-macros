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

    #expect(RecordSnapshotTrait.current == .missing)

    try await trait.provideScope {
      #expect(RecordSnapshotTrait.current == .all)
    }

    #expect(RecordSnapshotTrait.current == .missing)
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
