#if os(macOS)
import MacroTesting
import Testing

extension SnapshotTestTests {

  @Suite
  struct EscapedIdentifiers {
    @Test(arguments: [
      ("myTest", "myTest"),  // unchanged
      ("my test", "my_test_b41b25c1"),  // space -> _ + hash
      ("my-test", "my_test_b85fc79a"),  // dash -> _ + hash
      ("my---test", "my_test_ac23dc0c"),  // repeated dash collapse + hash
      ("my.test", "my_test_0ed32173"),  // dot -> _ + hash
      ("my/test", "my_test_b950c4d0"),  // slash -> _ + hash
      ("my@test", "my_test_3b4ea421"),  // @ -> _ + hash
      ("123 start", "_123_start_106da413"),  // leading digit prefix + hash
      ("_leading", "_leading"),  // keep leading _
      ("trailing_", "trailing_"),  // keep trailing _
      ("___", "___"),  // only underscores
      ("--a--", "_a__88f57a18"),  // symbol runs around letter + hash
      ("class", "class"),  // escaped keyword
      ("café", "café"),  // accented letters
      ("東京", "東京"),  // non-Latin letters
    ])
    func escapedFunctionName(functionName: String, generatedComponent: String) {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite
        struct SnapshotTests {
          @SnapshotTest
          func `\(functionName)`() -> some View {
            Text("test")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct SnapshotTests {
          func `\(functionName)`() -> some View {
            Text("test")
          }

          enum __generator_container_\(generatedComponent) {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "\(functionName)",
                configuration: configuration,
                makeValue: {
                  SnapshotTests().`\(functionName)`()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots)
          struct SnapshotTests_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func \(generatedComponent)_snapshotTest() async throws {
              let generator = __generator_container_\(generatedComponent).makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
          }
        }
        """
      }
    }
  }
}
#endif
