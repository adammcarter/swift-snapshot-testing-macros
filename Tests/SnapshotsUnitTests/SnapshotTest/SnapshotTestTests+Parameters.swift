#if os(macOS)
import MacroTesting
import Testing

extension SnapshotTestTests {

  @Suite(.tags(.parameters))
  struct Parameters {}
}
#endif
