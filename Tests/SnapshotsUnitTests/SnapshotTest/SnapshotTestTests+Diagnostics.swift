#if os(macOS)
import MacroTesting
import SnapshotsMacros
import SnapshotTestingMacros
import Testing

extension SnapshotTestTests {

  @Suite
  struct Diagnostics {

    @Test
    func testMissingSnapshotTestMacro() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct MyTests {
          func aTest() -> some View {
            Text("test")
          }
        }
        """
      } diagnostics: {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        ┬─────────────
        ╰─ ⚠️ Missing valid snapshot suite tests.
           ✏️ Remove the @SnapshotSuite attribute.
           ✏️ Add a function to make a SwiftUI view.
           ✏️ Add a function to make a UIView.
           ✏️ Add a function to make a UIViewController.
           ✏️ Add a function to make a NSView.
           ✏️ Add a function to make a NSViewController.
           ✏️ Add @SnapshotTest annotations to viable functions.
        struct MyTests {
          func aTest() -> some View {
            Text("test")
          }
        }
        """
      } fixes: {
        """
        @MainActor
        @Suite
        struct MyTests {
          func aTest() -> some View {
            Text("test")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct MyTests {
          func aTest() -> some View {
            Text("test")
          }
        }
        """
      }
    }
  }
}
#endif
