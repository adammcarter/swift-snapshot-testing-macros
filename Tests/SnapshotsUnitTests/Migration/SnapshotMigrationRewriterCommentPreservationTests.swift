import Testing

@testable import SnapshotMigrationSupport

@Suite
struct RewriterCommentPreservationTests {
  @Test
  func preservesCommentAboveTerminalReturn() throws {
    let input = """
    @SnapshotSuite
    struct CompareAdvertButtonSnapshotTests {
      @SnapshotTest
      func highlighted() -> UIView {
        let button = CompareAdvertButton()
        button.isHighlighted = true

        // important comment
        return button
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.isEmpty)
    #expect(result.changed)
    #expect(result.output.contains("// important comment"))
    // The comment keeps its blank-line separation and sits directly above the
    // rewritten terminal statement, indented once — not doubled.
    #expect(
      result.output.contains(
        """
            button.isHighlighted = true

            // important comment
            let snapshotValue = button
        """
      )
    )
  }

  @Test
  func preservesInlineTrailingCommentOnPreludeStatement() throws {
    let input = """
    @SnapshotSuite
    struct CompareAdvertButtonSnapshotTests {
      @SnapshotTest
      func highlighted() -> UIView {
        let button = CompareAdvertButton() // configure before snapshotting
        button.isHighlighted = true
        return button
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.isEmpty)
    #expect(result.changed)
    #expect(
      result.output.contains("let button = CompareAdvertButton() // configure before snapshotting")
    )
  }

  @Test
  func preservesDocCommentInsideBody() throws {
    let input = """
    @SnapshotSuite
    struct CompareAdvertButtonSnapshotTests {
      @SnapshotTest
      func highlighted() -> UIView {
        /// Prepares the button under test.
        let button = CompareAdvertButton()
        return button
      }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.isEmpty)
    #expect(result.changed)
    #expect(
      result.output.contains(
        """
            /// Prepares the button under test.
            let button = CompareAdvertButton()
        """
      )
    )
  }

  @Test
  func preservesCommentsInParameterizedConfigurationsBody() throws {
    let input = """
    @SnapshotTest(configurations: makeStates())
    func profile(state: UserState) -> some View {
      let model = makeModel(state: state) // shared fixture
      // render the profile
      return UserProfileView(model: model)
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.isEmpty)
    #expect(result.changed)
    #expect(result.output.contains("let model = makeModel(state: state) // shared fixture"))
    #expect(
      result.output.contains(
        """
          // render the profile
          let snapshotValue = UserProfileView(model: model)
        """
      )
    )
  }
}
