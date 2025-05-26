import SnapshotTestingMacros
import SwiftUI
import Testing

// Playground: noun - A place where people can play.

@Suite
@SnapshotSuite("My Snapshots")
struct MySnapshots {

//  @SnapshotTest(.mySetUp)
//  func myView() -> some View {
//    Text("Snapshot me")
//  }

  @SnapshotTest(.myConfigurationSetUp)
  func anotherView() -> some View {
    Text("Snapshot me")
  }
}

extension SnapshotTrait where Self == SnapshotSetUpTrait {
  static var mySetUp: Self {
    Self(setUp: { try await setUpTest() })
  }
}

private func setUpTest() async throws {
  print("Doing some setup ...")
}

// Needs type safety to only add this to a 'SnapshotConfiguration' ??
// This will also make sure that we get compiler errors if adding a bad configuration setup to a non-matching configuration value
extension SnapshotTrait where Self == SnapshotConfigurationSetUpTrait<Void> {
  static var myConfigurationSetUp: Self {
    Self(setUp: { try await setUpConfigurationTest(value: $0.value) })
  }
}

private func setUpConfigurationTest(value: Void) async throws {
  print("Doing some setup for configuration...", value)
}
