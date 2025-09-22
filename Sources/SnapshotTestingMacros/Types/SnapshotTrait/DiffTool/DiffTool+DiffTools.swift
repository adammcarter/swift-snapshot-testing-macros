import SnapshotTesting

extension DiffToolSnapshotTrait.DiffTool {
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
