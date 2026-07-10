#if os(macOS)
import AppKit
import CoreGraphics
import Testing

@testable import SnapshotTestingMacros

@MainActor
@Suite
struct SizeAssertionRequestGeneratorTests {
  @Test
  func generatesAllThemesForTwoSizes() async throws {
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
  func throwsNoSizesAvailableWhenSizesAreEmpty() async throws {
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

  // MARK: - Fixed length and scale validation
  //
  // Non-positive or non-finite fixed lengths must fail identically in EVERY width/height
  // combination. Before validation existed, `.fixed(0)` (or a negative value) combined with
  // `.minimum` silently dropped the constraint and measured the fully-compressed size, and
  // negative fixed sizes were misreported as "zero" errors.

  @Test
  func throwsInvalidFixedWidthBeforeInvalidFixedHeightForZeroByZero() async throws {
    let error = await sizeError(width: .fixed(0), height: .fixed(0))

    guard case .invalidFixedWidth(let value) = error else {
      Issue.record("Expected invalidFixedWidth, got: \(String(describing: error))")
      return
    }

    #expect(value == 0)
  }

  @Test
  func throwsInvalidFixedWidthForZeroWidth() async throws {
    let error = await sizeError(width: .fixed(0), height: .fixed(100))

    guard case .invalidFixedWidth(let value) = error else {
      Issue.record("Expected invalidFixedWidth, got: \(String(describing: error))")
      return
    }

    #expect(value == 0)
  }

  @Test
  func throwsInvalidFixedHeightForZeroHeight() async throws {
    let error = await sizeError(width: .fixed(100), height: .fixed(0))

    guard case .invalidFixedHeight(let value) = error else {
      Issue.record("Expected invalidFixedHeight, got: \(String(describing: error))")
      return
    }

    #expect(value == 0)
  }

  /// The core regression: a non-positive fixed length must NOT be silently treated as
  /// "unconstrained" just because the other dimension is `.minimum`.
  @Test
  func throwsInvalidFixedWidthForZeroWidthWithMinimumHeight() async throws {
    let error = await sizeError(width: .fixed(0), height: .minimum)

    guard case .invalidFixedWidth(let value) = error else {
      Issue.record("Expected invalidFixedWidth, got: \(String(describing: error))")
      return
    }

    #expect(value == 0)
  }

  @Test
  func throwsInvalidFixedHeightForNegativeHeightWithMinimumWidth() async throws {
    let error = await sizeError(width: .minimum, height: .fixed(-5))

    guard case .invalidFixedHeight(let value) = error else {
      Issue.record("Expected invalidFixedHeight, got: \(String(describing: error))")
      return
    }

    #expect(value == -5)
  }

  /// Negative sizes must report the offending value instead of masquerading as "zero width".
  @Test
  func throwsInvalidFixedWidthForNegativeWidth() async throws {
    let error = await sizeError(width: .fixed(-50), height: .fixed(200))

    guard case .invalidFixedWidth(let value) = error else {
      Issue.record("Expected invalidFixedWidth, got: \(String(describing: error))")
      return
    }

    #expect(value == -50)
  }

  @Test
  func throwsInvalidFixedWidthForNonFiniteWidth() async throws {
    let error = await sizeError(width: .fixed(.infinity), height: .fixed(200))

    guard case .invalidFixedWidth(let value) = error else {
      Issue.record("Expected invalidFixedWidth, got: \(String(describing: error))")
      return
    }

    #expect(value == .infinity)
  }

  @Test(arguments: [0.0, -1.0, Double.nan, Double.infinity])
  func throwsInvalidScaleForNonPositiveOrNonFiniteScale(scale: Double) async throws {
    let error = await sizeError(width: .fixed(100), height: .fixed(100), scale: scale)

    guard case .invalidScale(let value) = error else {
      Issue.record("Expected invalidScale, got: \(String(describing: error))")
      return
    }

    #expect(value == scale || (value.isNaN && scale.isNaN))
  }

  @Test
  func acceptsPositiveFiniteScale() async throws {
    let context = AssertionRequestGeneratorTestSupport.makeContext(
      traitConfiguration: .init(
        sizes: [
          AssertionRequestGeneratorTestSupport.makeTraitSize(
            width: .fixed(100),
            height: .fixed(100),
            scale: 2
          )
        ],
        theme: .light,
        strategy: .recursiveDescription
      )
    )

    let requests = try await SizeAssertionRequestGenerator(context: context).generateRequests()

    #expect(requests.count == 1)
  }

  private func sizeError(
    width: SizesSnapshotTrait.Length,
    height: SizesSnapshotTrait.Length,
    scale: Double? = nil
  ) async -> SizeAssertionRequestGenerator.SizeError? {
    let context = AssertionRequestGeneratorTestSupport.makeContext(
      traitConfiguration: .init(
        sizes: [
          AssertionRequestGeneratorTestSupport.makeTraitSize(
            width: width,
            height: height,
            scale: scale
          )
        ],
        theme: .light,
        strategy: .recursiveDescription
      )
    )

    do {
      _ = try await SizeAssertionRequestGenerator(context: context).generateRequests()
      return nil
    }
    catch let error as SizeAssertionRequestGenerator.SizeError {
      return error
    }
    catch {
      Issue.record("Expected a SizeError, got: \(error)")
      return nil
    }
  }

  @Test
  func usesContextSizesAndIgnoresTaskLocalSizes() async throws {
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
