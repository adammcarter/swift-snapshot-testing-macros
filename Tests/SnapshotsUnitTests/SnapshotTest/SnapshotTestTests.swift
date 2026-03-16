import Testing

#if os(macOS)
import MacroTesting
import SnapshotsMacros

@Suite(
  .macros(
    [
      "SnapshotSuite": SnapshotSuiteMacro.self,
      "SnapshotTest": SnapshotTestMacro.self,
    ],
    record: .missing
  )
)
struct SnapshotTestTests {}
#else
@Suite(.disabled("Unit tests only run on macOS"))
struct SnapshotTestTests {}
#endif
