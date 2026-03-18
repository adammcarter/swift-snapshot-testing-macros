import Testing

@testable import SnapshotTestingMacros

@Suite
struct SnapshotNameNormalizerTests {
  @Test(arguments: [
    ("Some name", "Some-name"),
    ("Some.name/with\\slashes", "Some-name-with-slashes"),
    ("---trim---", "trim"),
    ("name___with   spaces", "name___with-spaces"),
    ("", ""),
  ])
  func folderComponent(input: String, expected: String) {
    #expect(SnapshotNameNormalizer.folderComponent(from: input) == expected)
  }
}
