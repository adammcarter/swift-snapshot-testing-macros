#if os(macOS)
import AppKit
import CoreGraphics
import Testing

@testable import SnapshotTestingMacros

@MainActor
@Suite
struct AssertionRequestPipelineTests {
  @Test
  func `generates requests synchronously for the full generator pipeline`() throws {
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
        strategy: .image
      )
    )

    let requests = try SizeAssertionRequestGenerator(context: context).generateRequestsSync()

    #expect(requests.count == 4)
    #expect(
      Set(requests.map { $0.testName }) == [
        "base_test_name_description_1_light",
        "base_test_name_description_1_dark",
        "base_test_name_description_2_light",
        "base_test_name_description_2_dark",
      ]
    )
  }

  @Test
  func `generates requests for an end to end pipeline of generators`() async throws {
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
        strategy: .image
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

    let imageRequests = try requests.map { try #require($0 as? AssertionRequest<NSImage>) }

    #expect(imageRequests.count == 4)
    #expect(imageRequests.allSatisfy { $0.snapshotting.pathExtension == "png" })
  }
}
#endif
