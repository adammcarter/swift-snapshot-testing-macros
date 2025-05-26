import SnapshotTestingMacros
import SwiftUI
import Testing

// Playground: noun - A place where people can play.

@Suite
@SnapshotSuite("My Snapshots")
struct MySnapshots {

  @SnapshotTest(
    .mockCredentials
  )
  func myView() -> some View {
    Text("Snapshot me")
  }

  @SnapshotTest(
    .myConfigurationSetUp,
  )
  func anotherView() -> some View {
    Text("Snapshot me")
  }
}


public struct SnapshotSetUp: /*TestTrait, TestScoping, */SnapshotScoping, SnapshotTrait {
  public typealias SetUp = @Sendable () async throws -> Void

  let setUp: SetUp

  public var debugDescription: String {
    "SnapshotSetUpTrait"
  }

  public init(setUp: @escaping SetUp) {
    self.setUp = setUp
  }

  public func provideScope() async throws {
    try await setUp()
  }
}

extension SnapshotTrait where Self == SnapshotSetUp {
  static var mockCredentials: Self {
    Self(setUp: { try await setUpTest() })
  }
}

private func setUpTest() async throws {
  print("Doing some setup ...")
}


// Needs type safety to only add this to a 'SnapshotConfiguration' ??
// This will also make sure that we get compiler errors if adding a bad configuration setup to a non-matching configuration value
public struct SnapshotConfigurationSetUp<T: Sendable>: /*TestTrait, TestScoping, */ SnapshotConfigurationScoping, SnapshotTrait {
  public typealias Value = T

  public typealias SetUp = @Sendable (SnapshotConfiguration<T>) async throws -> Void

  let setUp: SetUp

  public var debugDescription: String {
    "SnapshotSetUpTrait"
  }

  public init(setUp: @escaping SetUp) {
    self.setUp = setUp
  }

  public func provideScope(
    for configuration: SnapshotConfiguration<Value>
  ) async throws where Value : Sendable {
    try await setUp(configuration)
  }
}

extension SnapshotTrait where Self == SnapshotConfigurationSetUp<Void> {
  static var myConfigurationSetUp: Self {
    Self(setUp: { try await setUpConfigurationTest(value: $0.value) })
  }
}

private func setUpConfigurationTest(value: Void) async throws {
  print("Doing some setup for configuration...", value)
}
