import Testing

@testable import SnapshotMigrationSupport

@Suite
struct TextEditApplierTests {
  @Test
  func preservesInsertionNestedInsideDeletion() {
    let source = "prefix DELETE suffix"

    let result = TextEditApplier.apply(
      edits: [
        TextEdit(startUTF8Offset: 7, endUTF8Offset: 13, replacement: ""),
        TextEdit(startUTF8Offset: 10, endUTF8Offset: 10, replacement: "INSERT"),
      ],
      to: source
    )

    #expect(result == "prefix INSERT suffix")
  }
}
