import CoreImage
import SwiftUI
import Testing
import XCTest

@testable import SnapshotTestingMacros

extension SnapshotTest.Traits.Size {

  @Suite
  struct FileDimensions {

    struct ExplicitSize {

      private static let width = 150
      private static let height = 250

      @Suite
      @SnapshotSuite(
        .backgroundColor(uiColor: .systemBackground)
      )
      struct DefaultScale {

        @SnapshotTest(
          .sizes(
            width: .fixed(width),
            height: .fixed(height)
          )
        )
        func referenceImage() -> some View {
          Text("\(ExplicitSize.width) x \(ExplicitSize.height) default scale reference image")
        }

        @Test(
          arguments: referenceImageFilePaths(named: "referenceImage_fixed-size")
        )
        func referenceImageHasExactDimensions(imagePathUrl: URL) throws {
          let (width, height) = try dimensionsOfImageAtURL(imagePathUrl)

          #expect(width == ExplicitSize.width * 3)
          #expect(height == ExplicitSize.height * 3)
        }
      }

      @Suite
      @SnapshotSuite(
        .backgroundColor(uiColor: .systemBackground)
      )
      struct ExplicitScale {

        @SnapshotTest(
          .sizes(
            width: .fixed(width),
            height: .fixed(height),
            scale: 1.0
          )
        )
        func oneReferenceImage() -> some View {
          Text("\(ExplicitSize.width) x \(ExplicitSize.height) 1.0 scale reference image")
        }

        @Test(
          arguments: referenceImageFilePaths(named: "oneReferenceImage_fixed-size")
        )
        func referenceImageHasExactDimensionsForSingleScale(imagePathUrl: URL) throws {
          let (width, height) = try dimensionsOfImageAtURL(imagePathUrl)

          #expect(width == ExplicitSize.width)
          #expect(height == ExplicitSize.height)
        }

        @SnapshotTest(
          .sizes(
            width: .fixed(width),
            height: .fixed(height),
            scale: 2.0
          )
        )
        func twoReferenceImage() -> some View {
          Text("\(ExplicitSize.width) x \(ExplicitSize.height) 2.0 scale reference image")
        }

        @Test(
          arguments: referenceImageFilePaths(named: "twoReferenceImage_fixed-size")
        )
        func referenceImageHasExactDimensionsForDoubleScale(imagePathUrl: URL) throws {
          let (width, height) = try dimensionsOfImageAtURL(imagePathUrl)

          #expect(width == ExplicitSize.width * 2)
          #expect(height == ExplicitSize.height * 2)
        }
      }
    }

    @Suite
    @SnapshotSuite(
      .backgroundColor(uiColor: .systemBackground)
    )
    struct DeviceSize {

      private static let device = SizesSnapshotTrait.Device.iPhoneX

      @SnapshotTest(
        .sizes(devices: device)
      )
      @ViewBuilder
      func referenceImage() -> some View {
        let sizeDescription = "\(Int(DeviceSize.device.width))x\(Int(DeviceSize.device.height)) @\(Int(DeviceSize.device.scale))x"

        Text("\(DeviceSize.device.debugDescription) \(sizeDescription) reference image")
      }

      @Test(
        arguments: referenceImageFilePaths(named: "referenceImage_iPhoneX")
      )
      func referenceImageHasExactDimensions(imagePathUrl: URL) throws {
        let (width, height) = try dimensionsOfImageAtURL(imagePathUrl)

        let device = DeviceSize.device

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
