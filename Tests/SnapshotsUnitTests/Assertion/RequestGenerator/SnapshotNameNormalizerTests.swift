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

  @Test(arguments: [
    ("Some name", "Some-name"),
    ("Menu/Item", "Menu/Item"),
    ("dealer is verified/has reply/view", "dealer-is-verified/has-reply/view"),
    ("Menu//Item/", "Menu/Item"),
    ("Menu/!!!", "Menu"),
    ("", ""),
  ])
  func folderPath(input: String, expected: String) {
    #expect(SnapshotNameNormalizer.folderPath(from: input) == expected)
  }
}
