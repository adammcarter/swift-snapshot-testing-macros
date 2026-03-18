#if os(macOS)
import AppKit
import CoreGraphics
import Testing

@testable import SnapshotTestingMacros

@MainActor
@Suite
struct SizeAssertionRequestGeneratorTests {
  @Test
  func `generates all themes for two sizes`() async throws {
    let context = AssertionRequestGeneratorTestSupport.makeContext(
      traitConfiguration: .init(
        sizes: [
          .init(
            width: .fixed(120),
            height: .fixed(80),
            displayName: "display_name_1",
            debugDescription: "debug_description_1",
            testNameDescription: "test_name_description_1"
          ),
          .init(
            width: .fixed(80),
            height: .fixed(120),
            displayName: "display_name_2",
            debugDescription: "debug_description_2",
            testNameDescription: "test_name_description_2"
          ),
        ],
        theme: .all,
        strategy: .recursiveDescription
      )
    )

    let requests = try await SizeAssertionRequestGenerator(context: context).generateRequests()

    #expect(requests.count == 4)
    #expect(
      Set(requests.map(\.testName)) == [
        "base_test_name_description_1_light",
        "base_test_name_description_1_dark",
        "base_test_name_description_2_light",
        "base_test_name_description_2_dark",
      ]
    )
    requests.forEach(AssertionRequestGeneratorTestSupport.assertCommonMetadata(_:))
    #expect(requests.allSatisfy { $0 is AssertionRequest<String> })
  }

  @Test
  func `throws no sizes available when sizes are empty`() async throws {
    let context = AssertionRequestGeneratorTestSupport.makeContext(
      traitConfiguration: .init(
        sizes: [],
        theme: .light,
        strategy: .recursiveDescription
      )
    )

    do {
      _ = try await SizeAssertionRequestGenerator(context: context).generateRequests()
      Issue.record("Expected noSizesAvailable")
    }
    catch let error as SizeAssertionRequestGenerator.SizeError {
      guard case .noSizesAvailable = error else {
        Issue.record("Expected noSizesAvailable, got: \(error.localizedDescription)")
        return
      }
    }
  }

  @Test
  func `throws zero size for fixed zero by zero`() async throws {
    let context = AssertionRequestGeneratorTestSupport.makeContext(
      traitConfiguration: .init(
        sizes: [
          .init(
            width: .fixed(0),
            height: .fixed(0),
            displayName: "display_name_1",
            debugDescription: "debug_description_1",
            testNameDescription: "test_name_description_1"
          )
        ],
        theme: .light,
        strategy: .recursiveDescription
      )
    )

    do {
      _ = try await SizeAssertionRequestGenerator(context: context).generateRequests()
      Issue.record("Expected zeroSize")
    }
    catch let error as SizeAssertionRequestGenerator.SizeError {
      guard case .zeroSize = error else {
        Issue.record("Expected zeroSize, got: \(error.localizedDescription)")
        return
      }
    }
  }

  @Test
  func `throws zero width for fixed zero width`() async throws {
    let context = AssertionRequestGeneratorTestSupport.makeContext(
      traitConfiguration: .init(
        sizes: [
          .init(
            width: .fixed(0),
            height: .fixed(100),
            displayName: "display_name_1",
            debugDescription: "debug_description_1",
            testNameDescription: "test_name_description_1"
          )
        ],
        theme: .light,
        strategy: .recursiveDescription
      )
    )

    do {
      _ = try await SizeAssertionRequestGenerator(context: context).generateRequests()
      Issue.record("Expected zeroWidth")
    }
    catch let error as SizeAssertionRequestGenerator.SizeError {
      guard case .zeroWidth = error else {
        Issue.record("Expected zeroWidth, got: \(error.localizedDescription)")
        return
      }
    }
  }

  @Test
  func `throws zero height for fixed zero height`() async throws {
    let context = AssertionRequestGeneratorTestSupport.makeContext(
      traitConfiguration: .init(
        sizes: [
          .init(
            width: .fixed(100),
            height: .fixed(0),
            displayName: "display_name_1",
            debugDescription: "debug_description_1",
            testNameDescription: "test_name_description_1"
          )
        ],
        theme: .light,
        strategy: .recursiveDescription
      )
    )

    do {
      _ = try await SizeAssertionRequestGenerator(context: context).generateRequests()
      Issue.record("Expected zeroHeight")
    }
    catch let error as SizeAssertionRequestGenerator.SizeError {
      guard case .zeroHeight = error else {
        Issue.record("Expected zeroHeight, got: \(error.localizedDescription)")
        return
      }
    }
  }

  @Test
  func `uses context sizes and ignores task local sizes`() async throws {
    let context = AssertionRequestGeneratorTestSupport.makeContext(
      traitConfiguration: .init(
        sizes: [
          .init(
            width: .fixed(120),
            height: .fixed(80),
            displayName: "display_name_1",
            debugDescription: "debug_description_1",
            testNameDescription: "test_name_description_1"
          )
        ],
        theme: .light,
        strategy: .recursiveDescription
      )
    )

    let requests = try await SizesSnapshotTrait.$current.withValue([
      .init(
        width: .fixed(50),
        height: .fixed(50),
        displayName: "display_name_ignored",
        debugDescription: "debug_description_ignored",
        testNameDescription: "test_name_description_ignored"
      ),
      .init(
        width: .fixed(60),
        height: .fixed(60),
        displayName: "display_name_ignored_2",
        debugDescription: "debug_description_ignored_2",
        testNameDescription: "test_name_description_ignored_2"
      ),
    ]) {
      try await SizeAssertionRequestGenerator(context: context).generateRequests()
    }

    #expect(requests.count == 1)
    #expect(requests.map(\.testName) == ["base_test_name_description_1_light"])
  }
}
#endif
