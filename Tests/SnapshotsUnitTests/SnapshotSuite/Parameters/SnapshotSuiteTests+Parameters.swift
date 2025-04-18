#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests {

  @Suite(.tags(.parameters))
  struct Parameters {}
}
#endif
