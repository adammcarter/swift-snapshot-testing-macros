#if canImport(UIKit)
import CoreImage
import SnapshotSupport
import SwiftUI
import Testing
import XCTest

@testable import SnapshotTestingMacros

extension SnapshotTest.Traits.Size {

  struct FileDimensions {}
}

// MARK: - Explicit sized images

// MARK: Default scale

extension SnapshotTest.Traits.Size.FileDimensions {

  struct ExplicitSize {}
}

extension SnapshotTest.Traits.Size.FileDimensions.ExplicitSize {

  private static let oneScaleSize = CGSize(width: 150, height: 250)

  @MainActor
  @Suite
  @SnapshotSuite(
    .backgroundColor(.white),
    .theme(.light)
  )
  struct DefaultScale {

    private static let deviceScale = UIScreen.main.scale
    private static let defaultScaleSize = oneScaleSize * deviceScale

    @Test
    func referenceImageHasExactDimensions() throws {
      try expectImageSizeIsCorrect(
        fileName: "referenceImage_fixed-size",
        width: DefaultScale.defaultScaleSize.width,
        height: DefaultScale.defaultScaleSize.height
      )
    }

    // Make the reference images:

    @SnapshotTest(
      .sizes(
        width: .fixed(oneScaleSize.width),
        height: .fixed(oneScaleSize.height)
      )
    )
    func referenceImage() -> some View {
      Text("\(oneScaleSize.formatted()) default scale (\(DefaultScale.deviceScale.formattedAsScale())) reference image (\(DefaultScale.defaultScaleSize.formatted()))")
    }
  }
}

// MARK: Explicit scale

extension SnapshotTest.Traits.Size.FileDimensions.ExplicitSize {

  private static let twoScaleSize = oneScaleSize * 2
  private static let threeScaleSize = oneScaleSize * 3

  @Suite
  @SnapshotSuite(
    .backgroundColor(.white),
    .theme(.light)
  )
  struct ExplicitScale {

    @Test(
      arguments: [
        ("oneReferenceImage_fixed-size", oneScaleSize),
        ("twoReferenceImage_fixed-size", twoScaleSize),
        ("threeReferenceImage_fixed-size", threeScaleSize),
      ]
    )
    func referenceImageHasExactFileDimensionsForScale(
      fileName: String,
      scaledSize: CGSize
    ) throws {
      try expectImageSizeIsCorrect(
        fileName: fileName,
        width: scaledSize.width,
        height: scaledSize.height
      )
    }

    // Make the reference images:

    @SnapshotTest(
      .sizes(
        width: .fixed(oneScaleSize.width),
        height: .fixed(oneScaleSize.height),
        scale: 1.0
      )
    )
    func oneReferenceImage() -> some View {
      makeText(scale: 1.0, scaledSize: oneScaleSize)
    }

    @SnapshotTest(
      .sizes(
        width: .fixed(oneScaleSize.width),
        height: .fixed(oneScaleSize.height),
        scale: 2.0
      )
    )
    func twoReferenceImage() -> some View {
      makeText(scale: 2.0, scaledSize: twoScaleSize)
    }

    @SnapshotTest(
      .sizes(
        width: .fixed(oneScaleSize.width),
        height: .fixed(oneScaleSize.height),
        scale: 3.0
      )
    )
    func threeReferenceImage() -> some View {
      makeText(scale: 3.0, scaledSize: threeScaleSize)
    }

    private func makeText(
      scale: Double,
      scaledSize: CGSize
    ) -> Text {
      Text("\(oneScaleSize.formatted()) \(scale.formattedAsScale()) scale reference image (\(scaledSize.formatted()))")
    }
  }
}

// MARK: - Devices

extension SnapshotTest.Traits.Size.FileDimensions {

  private static let device = SizesSnapshotTrait.Device.iPhoneX
  private static let deviceSize = CGSize(width: device.width, height: device.height)
  private static let deviceScaleSize = deviceSize * device.scale

  @Suite
  @SnapshotSuite(
    .backgroundColor(.white),
    .theme(.light)
  )
  struct DeviceSize {

    @Test
    func referenceImageHasExactDimensions() throws {
      try expectImageSizeIsCorrect(
        fileName: "referenceImage_iPhoneX",
        width: deviceScaleSize.width,
        height: deviceScaleSize.height
      )
    }

    // Make the reference images:

    @SnapshotTest(
      .sizes(devices: device)
    )
    @ViewBuilder
    func referenceImage() -> some View {
      let sizeDescription = "\(deviceSize.formatted()) \(device.scale.formattedAsScale())"

      Text("\(device.debugDescription) \(sizeDescription) reference image (\(deviceScaleSize.formatted()))")
    }
  }
}

// MARK: - Helpers

private func expectImageSizeIsCorrect(
  fileName: String,
  width: CGFloat,
  height: CGFloat
) throws {
  let imagePathUrl = try referenceImageFilePaths(named: fileName)
  let (width, height) = try dimensionsOfImageAtURL(imagePathUrl)

  #expect(width == width)
  #expect(height == height)
}

private func referenceImageFilePaths(named fileName: String) throws -> URL {
  let referenceImagesPath = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("__Snapshots__")
    .appendingPathComponent("SnapshotTest+Traits+Size+FileDimensions")
    .path

  let subpaths =
    try? FileManager
    .default
    .subpathsOfDirectory(atPath: referenceImagesPath)

  let url = (subpaths ?? [])
    .first {
      $0.contains(fileName)
    }
    .flatMap {
      URL(fileURLWithPath: referenceImagesPath).appendingPathComponent($0)
    }

  return try #require(url, "Missing reference image for file name: \(fileName)")
}

private func dimensionsOfImageAtURL(_ imagePathUrl: URL) throws -> (CGFloat, CGFloat) {
  let imageSource = try #require(CGImageSourceCreateWithURL(imagePathUrl as CFURL, nil))
  let properties = try #require(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any])
  let pixelWidth = try #require(properties[kCGImagePropertyPixelWidth] as? Int)
  let pixelHeight = try #require(properties[kCGImagePropertyPixelHeight] as? Int)

  return (CGFloat(pixelWidth), CGFloat(pixelHeight))
}

extension CGSize {
  fileprivate func formatted() -> String {
    "\(width.formatted())x\(height.formatted())"
  }
}

extension CGFloat {
  fileprivate func formattedAsScale() -> String {
    "@\(formatted())x"
  }
}

extension Double {
  fileprivate func formattedAsScale() -> String {
    CGFloat(self).formattedAsScale()
  }
}
#endif
