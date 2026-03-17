#if os(macOS)
@testable import SnapshotTestingMacros
import Testing

struct SizesSnapshotTraitDeviceTests {
  struct ExpectedDevice: Sendable {
    let device: SizesSnapshotTrait.Device
    let width: Double
    let height: Double
    let scale: Double
    let debugDescription: String
  }

  static let expectedDevices: [ExpectedDevice] = [
    .init(device: .iPhoneSE, width: 320, height: 568, scale: 2, debugDescription: "iPhoneSE"),
    .init(device: .iPhone8, width: 375, height: 667, scale: 2, debugDescription: "iPhone8"),
    .init(device: .iPhone8Plus, width: 414, height: 736, scale: 3, debugDescription: "iPhone8Plus"),
    .init(device: .iPhoneX, width: 375, height: 812, scale: 3, debugDescription: "iPhoneX"),
    .init(device: .iPhoneXsMax, width: 414, height: 896, scale: 3, debugDescription: "iPhoneXsMax"),
    .init(device: .iPhoneXr, width: 414, height: 896, scale: 2, debugDescription: "iPhoneXr"),
    .init(device: .iPhone12, width: 390, height: 844, scale: 3, debugDescription: "iPhone12"),
    .init(device: .iPhone12Pro, width: 390, height: 844, scale: 3, debugDescription: "iPhone12Pro"),
    .init(device: .iPhone12ProMax, width: 428, height: 926, scale: 3, debugDescription: "iPhone12ProMax"),
    .init(device: .iPhone13, width: 390, height: 844, scale: 3, debugDescription: "iPhone13"),
    .init(device: .iPhone13Mini, width: 375, height: 812, scale: 3, debugDescription: "iPhone13Mini"),
    .init(device: .iPhone13Pro, width: 390, height: 844, scale: 3, debugDescription: "iPhone13Pro"),
    .init(device: .iPhone13ProMax, width: 428, height: 926, scale: 3, debugDescription: "iPhone13ProMax"),
    .init(device: .iPadMini, width: 1024, height: 768, scale: 2, debugDescription: "iPadMini"),
    .init(device: .iPad9_7, width: 1024, height: 768, scale: 2, debugDescription: "iPad9_7"),
    .init(device: .iPad10_2, width: 1080, height: 810, scale: 2, debugDescription: "iPad10_2"),
    .init(device: .iPadPro10_5, width: 1112, height: 834, scale: 2, debugDescription: "iPadPro10_5"),
    .init(device: .iPadPro11, width: 1194, height: 834, scale: 2, debugDescription: "iPadPro11"),
    .init(device: .iPadPro12_9, width: 1366, height: 1024, scale: 2, debugDescription: "iPadPro12_9"),
  ]

  @Test
  func allCases_matchExpectedPointFreeDimensions() {
    #expect(SizesSnapshotTrait.Device.allCases.count == Self.expectedDevices.count)
    #expect(Set(Self.expectedDevices.map(\.debugDescription)).count == Self.expectedDevices.count)
    #expect(
      Self.expectedDevices.map(\.debugDescription).sorted()
        == SizesSnapshotTrait.Device.allCases.map(\.debugDescription).sorted()
    )
  }

  @Test(arguments: expectedDevices)
  func allCases_haveExpectedDimensions(entry: ExpectedDevice) {
    #expect(entry.device.width == entry.width)
    #expect(entry.device.height == entry.height)
    #expect(entry.device.scale == entry.scale)
    #expect(entry.device.debugDescription == entry.debugDescription)
  }
}
#endif
