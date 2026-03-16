import SnapshotTesting

extension DiffToolSnapshotTrait.DiffTool {
  /// A diff tool that uses the `imagediff` command line tool.
  public static var imageDiff: Self {
    .init {
      """
      imagediff \\
        "\($0)" \\
        "\($1)"
      """
    }
  }
}
