#if os(macOS)
import MacroTesting
import Testing

extension SnapshotSuiteTests.Parameters {

  /// A suite display name is only a per-test fallback. When two or more tests would fall back
  /// to the same suite display name, every artifact they produce would resolve to the same
  /// reference file — persistent false failures, or silent overwrites in record mode. The
  /// generated tests must disambiguate the fallback per test as `<suite name>/<function name>`
  /// while the single-test fallback keeps producing main's artifact names unchanged.
  @Suite
  struct DisplayNameCollision {

    @Test
    func testTwoTestsInNamedSuiteResolveDistinctDisplayNames() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite("Some name")
        struct MySuite {
          @SnapshotTest
          func makeFirstView() -> some View {
            Text("first")
          }

          @SnapshotTest
          func makeSecondView() -> some View {
            Text("second")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct MySuite {
          func makeFirstView() -> some View {
            Text("first")
          }

          enum __generator_container_makeFirstView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "Some name",
                configuration: configuration,
                makeValue: {
                  MySuite().makeFirstView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }
          func makeSecondView() -> some View {
            Text("second")
          }

          enum __generator_container_makeSecondView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "Some name",
                configuration: configuration,
                makeValue: {
                  MySuite().makeSecondView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 10,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots)
          struct MySuite_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeFirstView_snapshotTest() async throws {
              let generator = SnapshotTestingMacros.__overridingDisplayName(of: __generator_container_makeFirstView.makeGenerator(configuration: .none), with: "Some name/makeFirstView")

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }

            @MainActor
            @Test()
            func makeSecondView_snapshotTest() async throws {
              let generator = SnapshotTestingMacros.__overridingDisplayName(of: __generator_container_makeSecondView.makeGenerator(configuration: .none), with: "Some name/makeSecondView")

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }
          }
        }
        """
      }
    }

    /// Only tests that actually share the suite-name fallback are disambiguated. A test with
    /// its own display name never collides through the fallback, so the single remaining
    /// fallback test keeps main's suite-named artifacts unchanged.
    @Test
    func testExplicitTestDisplayNameLeavesSingleFallbackTestUntouched() {
      assertMacro {
        """
        @MainActor
        @Suite
        @SnapshotSuite("Some name")
        struct MySuite {
          @SnapshotTest("First name")
          func makeFirstView() -> some View {
            Text("first")
          }

          @SnapshotTest
          func makeSecondView() -> some View {
            Text("second")
          }
        }
        """
      } expansion: {
        """
        @MainActor
        @Suite
        struct MySuite {
          func makeFirstView() -> some View {
            Text("first")
          }

          enum __generator_container_makeFirstView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "First name",
                configuration: configuration,
                makeValue: {
                  MySuite().makeFirstView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 5,
                column: 3
              )
            }
          }
          func makeSecondView() -> some View {
            Text("second")
          }

          enum __generator_container_makeSecondView {
            @MainActor
            static func makeGenerator(configuration: SnapshotTestingMacros.SnapshotConfiguration<Void>) -> any SnapshotTestingMacros.SnapshotViewGenerating {
              SnapshotTestingMacros.SnapshotViewGenerator<Void>(
                displayName: "Some name",
                configuration: configuration,
                makeValue: {
                  MySuite().makeSecondView()
                },
                fileID: #fileID,
                filePath: #filePath,
                line: 10,
                column: 3
              )
            }
          }

          @MainActor
          @Suite(.pointfreeSnapshots)
          struct MySuite_GeneratedSnapshotSuite {

            @MainActor
            @Test()
            func makeFirstView_snapshotTest() async throws {
              let generator = __generator_container_makeFirstView.makeGenerator(configuration: .none)

              try await SnapshotTestingMacros.assertSnapshot(with: generator)
            }

            @MainActor
            @Test()
            func makeSecondView_snapshotTest() async throws {
              let generator = __generator_container_makeSecondView.makeGenerator(configuration: .none)

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
