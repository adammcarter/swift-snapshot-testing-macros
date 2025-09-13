import CoreImage
import SwiftUI
import Testing
import XCTest

@testable import SnapshotTestingMacros

extension SnapshotTest.Traits.Size {

  @Suite
  struct FileDimensions {

    @Suite
    @SnapshotSuite(
      .backgroundColor(uiColor: .systemBackground)
    )
    struct Explicit {

      private static let width = 150
      private static let height = 250

      @SnapshotTest(
        .sizes(
          width: .fixed(width),
          height: .fixed(height)
        )
      )
      func referenceImage() -> some View {
        Text("\(Explicit.width) x \(Explicit.height) reference image")
      }

      @Test(
        arguments: referenceImageFilePaths(named: "referenceImage_fixed-size")
      )
      func referenceImageHasExactDimensions(imagePathUrl: URL) throws {
        let (width, height) = try dimensionsOfImageAtURL(imagePathUrl)

        #expect(width == Explicit.width)
        #expect(height == Explicit.height)
      }
    }

    @Suite
    @SnapshotSuite(
      .backgroundColor(uiColor: .systemBackground)
    )
    struct Device {

      private static let device = SizesSnapshotTrait.Device.iPhoneX

      @SnapshotTest(
        .sizes(devices: device)
      )
      @ViewBuilder
      func referenceImage() -> some View {
        let sizeDescription = "\(Int(Device.device.width))x\(Int(Device.device.height)) @\(Int(Device.device.scale))x"

        Text("\(Device.device.debugDescription) \(sizeDescription) reference image")
      }

      @Test(
        arguments: referenceImageFilePaths(named: "referenceImage_iPhoneX")
      )
      func referenceImageHasExactDimensions(imagePathUrl: URL) throws {
        let (width, height) = try dimensionsOfImageAtURL(imagePathUrl)

        let device = Device.device

        #expect(width == Int(device.width * device.scale))
        #expect(height == Int(device.height * device.scale))
      }
    }
  }
}

private func referenceImageFilePaths(named fileName: String) -> [URL] {
  let referenceImagesPath = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("__Snapshots__")
    .appendingPathComponent("SnapshotTest+Traits+Size+FileDimensions")
    .path

  let subpaths =
    try? FileManager
    .default
    .subpathsOfDirectory(atPath: referenceImagesPath)

  return (subpaths ?? [])
    .filter {
      $0.contains(fileName)
    }
    .map {
      URL(fileURLWithPath: referenceImagesPath).appendingPathComponent($0)
    }
}

private func dimensionsOfImageAtURL(_ imagePathUrl: URL) throws -> (Int, Int) {
  let imageSource = try XCTUnwrap(CGImageSourceCreateWithURL(imagePathUrl as CFURL, nil))
  let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any])
  let pixelWidth = try XCTUnwrap(properties[kCGImagePropertyPixelWidth] as? Int)
  let pixelHeight = try XCTUnwrap(properties[kCGImagePropertyPixelHeight] as? Int)

  return (pixelWidth, pixelHeight)
}
