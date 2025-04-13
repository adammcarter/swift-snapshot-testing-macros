#if os(macOS)
import MacroTesting
import SnapshotsMacros
import Testing

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
import Testing

#warning("TODO: these tests and others in this module only seem to build for mac, needs looking in to...")

@Suite(.disabled("Tests do not run on iOS - fix me")) enum Skip {}

#endif
