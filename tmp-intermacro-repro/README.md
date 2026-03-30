## SwiftTestingInterMacroRepro

Minimal standalone repro for a Swift Testing expansion failure when a second macro generates a `@Test` method inside an extension-scoped `@Suite`.

### Repro

The failing source is:

```swift
import Testing
import SwiftTestingInterMacroRepro

struct Container {}

extension Container {
  @Suite
  @GenerateTest
  struct ExtensionScopedSuite {}
}
```

`@GenerateTest` expands to:

```swift
@Test
func generatedByMacro() async throws {}
```

The equivalent hand-written Swift Testing code does not reproduce:

```swift
extension Container {
  @Suite
  struct HandwrittenSuite {
    @Test
    func generatedByMacro() async throws {}
  }
}
```

### Expected

The macro-generated `@Test` should compile the same way as the hand-written equivalent.

### Actual

Swift Testing emits invalid generated code for the macro-generated `@Test`, with errors such as:

- `cannot use instance member '...' within property initializer; property initializers run before 'self' is available`
- `properties with attribute @used must be static`
- `properties with attribute @section must be static`

### Running

With Xcode 26.4 selected:

```bash
swift test --disable-sandbox
```

Or:

```bash
DEVELOPER_DIR=/Applications/Xcode-26.4.0.app/Contents/Developer swift test --disable-sandbox
```

### Notes

- In my local verification, this standalone repro also fails under Xcode 26.3 after lowering the package tools version to 6.2.
- That suggests the broader inter-macro issue predates 26.4, even though a larger package may surface it differently on newer toolchains.
