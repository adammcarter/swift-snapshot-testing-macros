import Testing

@testable import SnapshotMigrationSupport

@Suite
struct MigrationAttributeFormattingTests {
  @Test
  func removesWhitespaceOnlyLinesInsideMigratedAttributeBlock() throws {
    let input = "@MainActor" + "\n   \n" + """
    @SnapshotSuite(.theme(.light))
    struct CardSnapshots {
      @SnapshotTest
      func card() -> some View { CardView() }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.isEmpty)
    #expect(
      result.output.hasPrefix(
        """
        @MainActor
        @Suite(.theme(.light))
        struct CardSnapshots
        """
      )
    )
    expectParsesCleanly(result.output)
  }

  @Test
  func normalizesSnapshotSuiteBeforeExistingSuite() throws {
    let input = """
    @MainActor
    @SnapshotSuite(.sizes(.minimum))

    @Suite("Cards")
    struct CardSnapshots {
      @SnapshotTest
      func card() -> some View { CardView() }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.isEmpty)
    #expect(
      result.output.hasPrefix(
        """
        @MainActor
        @Suite("Cards", .sizes(.minimum))
        struct CardSnapshots
        """
      )
    )
    expectParsesCleanly(result.output)
  }

  @Test
  func collapsesMultipleDuplicateSuiteSeparators() throws {
    let input = """
    @MainActor
    @Suite
    """ + "\n  \t\n" + """
    @Suite
    @SnapshotSuite(.theme(.dark))
    struct CardSnapshots {
      @SnapshotTest
      func card() -> some View { CardView() }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.isEmpty)
    #expect(
      result.output.hasPrefix(
        """
        @MainActor
        @Suite(.theme(.dark))
        struct CardSnapshots
        """
      )
    )
    #expect(result.output.components(separatedBy: "@Suite").count - 1 == 1)
    expectParsesCleanly(result.output)
  }

  @Test
  func splitsSameLineAttributesWhenBlockIsMigrated() throws {
    let input = """
    @MainActor @SnapshotSuite
    struct CardSnapshots {
      @SnapshotTest
      func card() -> some View { CardView() }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.isEmpty)
    #expect(
      result.output.hasPrefix(
        """
        @MainActor
        @Suite
        struct CardSnapshots
        """
      )
    )
    expectParsesCleanly(result.output)
  }

  @Test
  func preservesCommentsWhileRemovingBlankAttributeSeparators() throws {
    let input = """
    @MainActor

    // Rendering is process-global.
    """ + "\n  \t\n" + """
    @SnapshotSuite(.serialized)
    struct CardSnapshots {
      @SnapshotTest
      func card() -> some View { CardView() }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.isEmpty)
    #expect(
      result.output.hasPrefix(
        """
        @MainActor
        // Rendering is process-global.
        @Suite(.serialized)
        struct CardSnapshots
        """
      )
    )
    expectParsesCleanly(result.output)
  }

  @Test
  func preservesTrailingAttributeComment() throws {
    let input = """
    @MainActor // UI rendering

    @SnapshotSuite
    struct CardSnapshots {
      @SnapshotTest
      func card() -> some View { CardView() }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.isEmpty)
    #expect(
      result.output.hasPrefix(
        """
        @MainActor // UI rendering
        @Suite
        struct CardSnapshots
        """
      )
    )
    expectParsesCleanly(result.output)
  }

  @Test
  func retainsNestedDeclarationIndentation() throws {
    let input = """
    enum Namespace {
        @available(iOS 17, *)

        @SnapshotSuite
        struct CardSnapshots {
          @SnapshotTest
          func card() -> some View { CardView() }
        }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.isEmpty)
    #expect(
      result.output.contains(
        """
            @MainActor
            @available(iOS 17, *)
            @Suite
            struct CardSnapshots
        """
      )
    )
    expectParsesCleanly(result.output)
  }

  @Test
  func retainsCRLFInMigratedAttributeBlock() throws {
    let input = [
      "@MainActor",
      "",
      "@SnapshotSuite",
      "struct CardSnapshots {",
      "  @SnapshotTest",
      "  func card() -> some View { CardView() }",
      "}",
    ].joined(separator: "\r\n")

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.isEmpty)
    #expect(result.output.hasPrefix("@MainActor\r\n@Suite\r\nstruct CardSnapshots"))
    expectParsesCleanly(result.output)
  }

  @Test
  func isIdempotentAfterAttributeNormalization() throws {
    let input = "@MainActor" + "\n  \t\n" + """
    @SnapshotSuite
    struct CardSnapshots {
      @SnapshotTest
      func card() -> some View { CardView() }
    }
    """

    let first = try SnapshotMigrationRewriter().rewrite(source: input)
    let second = try SnapshotMigrationRewriter().rewrite(source: first.output)

    #expect(first.reasons.isEmpty)
    #expect(second.reasons.isEmpty)
    #expect(second.output == first.output)
    #expect(!second.changed)
    expectParsesCleanly(first.output)
  }

  @Test
  func normalizesInsertedMainActorWithExistingFunctionAttributes() throws {
    let input = """
    @available(macOS 15, *)

    @SnapshotTest
    func card() -> some View { CardView() }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.isEmpty)
    #expect(
      result.output.hasPrefix(
        """
        @MainActor
        @available(macOS 15, *)
        @Test
        func card()
        """
      )
    )
    expectParsesCleanly(result.output)
  }

  @Test(arguments: ["\n", "\n\n", "\n \t\n\n", "\r\n\r\n"])
  func preservesTestableImportBoundaryWhenSuiteEditsOverlap(boundary: String) throws {
    let prefix = "@testable import MyApp\(boundary)"
    let input = prefix + """
      @Suite
      @SnapshotSuite(.theme(.light))
      struct CardSnapshots {
        @SnapshotTest
        func card() -> some View { CardView() }
      }
      """

    let first = try SnapshotMigrationRewriter().rewrite(source: input)
    let second = try SnapshotMigrationRewriter().rewrite(source: first.output)

    #expect(first.reasons.isEmpty)
    #expect(first.output.hasPrefix(prefix + "@MainActor"))
    #expect(first.output.components(separatedBy: "@Suite").count - 1 == 1)
    #expect(!first.output.contains("MyAppctor"))
    #expect(second.output == first.output)
    expectParsesCleanly(first.output)
  }

  @Test
  func doesNotNormalizeUnrelatedAttributeBlocks() throws {
    let unrelatedPrefix = "@available(macOS 15, *)" + "\n   \n" + """
    @MainActor
    struct Unrelated {}

    """
    let input = unrelatedPrefix + """
    @SnapshotSuite
    struct CardSnapshots {
      @SnapshotTest
      func card() -> some View { CardView() }
    }
    """

    let result = try SnapshotMigrationRewriter().rewrite(source: input)

    #expect(result.reasons.isEmpty)
    #expect(result.output.hasPrefix(unrelatedPrefix))
    #expect(result.output.contains("@MainActor\n@Suite\nstruct CardSnapshots"))
    expectParsesCleanly(result.output)
  }
}
