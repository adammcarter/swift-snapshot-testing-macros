import CoreGraphics

struct NameAssertionRequestGenerator: AssertionRequestGenerating {
  let context: AssertionRequestContext

  let traitSize: SizesSnapshotTrait.Size
  let size: CGSize
  let theme: SnapshotTheme
  let displayScale: Double

  /**
   The following, in order, joined by an underscore.
   Any subcomponent should replace spaces with a hyphen.

   test display name, configuration name, size trait, theme trait
   */
  private var testName: String {
    [
      context.name,
      traitSize.testNameDescription,
      theme.testNameDescription,
    ]
    .joined(separator: "_")
  }

  func generateRequests() async throws -> [any AssertionRequesting] {
    let base = StrategyAssertionRequestGenerator(
      context: context,
      size: size,
      theme: theme,
      displayScale: displayScale,
      testName: testName
    )

    return try await base.generateRequests()
  }
}

@MainActor
extension SnapshotTheme {
  var testNameDescription: String {
    #if canImport(UIKit)
    switch self {
      case .dark: "dark"
      case .light: "light"
      case .unspecified: "unspecified"
      @unknown default: "unknown"
    }
    #elseif canImport(AppKit)
    switch self.name {
      case .darkAqua: "dark"
      case .aqua: "light"
      default: "unknown"
    }
    #endif
  }
}
