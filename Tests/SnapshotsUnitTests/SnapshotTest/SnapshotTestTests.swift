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
#warning("TODO: these tests and others in this module only seem to build for mac, needs looking in to...")

@Suite(.disabled("Unit tests only run on macOS")) enum Skip {}
#endif
