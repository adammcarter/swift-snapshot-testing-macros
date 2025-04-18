#if os(macOS)
import MacroTesting
import Testing

extension SnapshotTestTests {

  @Suite(.tags(.configurations))
  struct Configurations {}
}
#endif
