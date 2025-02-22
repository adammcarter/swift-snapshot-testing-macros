#if os(macOS)
import MacroTesting
import SnapshotsMacros
import SnapshotTestingMacros
import Testing

@Suite(
  .macros(
    [
      "SnapshotSuite": SnapshotSuiteMacro.self
    ],
    record: .missing
  )
)
struct SnapshotSuiteTests {}
#endif
