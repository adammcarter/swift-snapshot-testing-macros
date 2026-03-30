import Testing
@testable import tmp_swift_testing_repro

enum OuterNamespace {
  enum NestedNamespace {}
}

extension OuterNamespace {
  @Suite
  struct ExtensionScopedSuite {
    @Test
    func extensionScopedInstanceTest() async throws {}
  }

  @Suite
  struct GeneratedHostSuite {
    func helper() {}

    enum GeneratorContainer {
      @MainActor
      static func makeGenerator() {}
    }
  }

  @MainActor
  @Suite
  struct GeneratedPeerSuite {
    @MainActor
    @Test()
    func generatedPeerInstanceTest() async throws {
      GeneratedHostSuite.GeneratorContainer.makeGenerator()
    }
  }

  @Suite
  struct StaticSuite {
    @Test()
    static func staticExtensionScopedTest() async throws {}
  }
}

extension OuterNamespace.NestedNamespace {
  @Suite
  struct NestedExtensionScopedSuite {
    @Test
    func nestedExtensionScopedInstanceTest() async throws {}
  }
}

@Suite
struct TopLevelSuite {
  @Test
  func topLevelInstanceTest() async throws {}
}
