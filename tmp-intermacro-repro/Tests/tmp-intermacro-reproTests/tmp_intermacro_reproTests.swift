import Testing
import SwiftTestingInterMacroRepro

struct Container {}

extension Container {
  @Suite
  @GenerateTest
  struct ExtensionScopedSuite {}
}
