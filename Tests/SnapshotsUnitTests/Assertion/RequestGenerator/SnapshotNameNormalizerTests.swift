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
    ("Card", "card"),
    ("card", "card"),
    ("Min Size", "min-size"),
    ("min-size", "min-size"),
    ("---Trim---", "trim"),
    ("", ""),
  ])
  func referenceFileKey(input: String, expected: String) {
    #expect(SnapshotNameNormalizer.referenceFileKey(from: input) == expected)
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

  /*
   Two names that are canonically equivalent but differently encoded — `é` as one scalar
   (NFC) versus `e` + a combining accent (NFD) — are one file on the case- and
   normalization-insensitive Apple filesystems, exactly like `Card` and `card`. Their
   reference keys must therefore collide.

   This is a regression guard, not a fix: `referenceFileKey` needs no explicit normalization
   because Swift `String` equality and hashing already fold canonical equivalence, and the
   collision machinery keys off `Set<String>` / `[String: Int]`. That is easy to break
   silently — comparing `.utf8` bytes, storing `Data`, or normalizing one code path and not
   another would make these keys diverge and let the second name overwrite the first's
   reference on disk. This pins the property so that regression fails loudly.
   */
  @Test(arguments: [
    ("caf\u{00E9}", "cafe\u{0301}"),          // café — NFC vs NFD
    ("Sch\u{00F6}n", "Scho\u{0308}n"),        // Schön — NFC vs NFD
    ("Caf\u{00E9}", "cafe\u{0301}"),          // case difference AND normalization difference
  ])
  func canonicallyEquivalentNamesShareOneReferenceKey(nfc: String, nfd: String) {
    let nfcKey = SnapshotNameNormalizer.referenceFileKey(from: nfc)
    let nfdKey = SnapshotNameNormalizer.referenceFileKey(from: nfd)

    #expect(nfcKey == nfdKey)
    // Model the real collision store: both names must occupy one slot, not two.
    #expect(Set([nfcKey, nfdKey]).count == 1)
  }
}
