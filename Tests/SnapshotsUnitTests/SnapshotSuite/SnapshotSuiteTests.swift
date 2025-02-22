#if os(macOS)
import MacroTesting
import SnapshotsMacros
import SnapshotTestingMacros
import Testing

@Suite(
  .macros(
    record: .missing,
    macros: [
      "SnapshotSuite": SnapshotSuiteMacro.self
    ]
  )
)
struct SnapshotSuiteTests {}
#endif
