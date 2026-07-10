// The committed references in __Snapshots__ are recorded on the iOS simulator (the CI
// integration job's platform). Artifact names carry no platform dimension, so running this
// suite on macOS renders via AppKit and can never match those references — gate it to UIKit
// like the legacy migration fixtures (and the repetition target). Dedicated AppKit runtime
// coverage lives in the ExpectSnapshot+AppKitRuntimeTests unit suites with macOS references.
#if canImport(UIKit)
import SnapshotTestingMacros
import SwiftUI
import Testing

enum Layout: Sendable {
  case compact
  case regular
}

enum UserState: Sendable {
  case loggedOut
  case loggedIn
}

struct ExpectSnapshotConfigurationsTests {
  @Test(arguments: [
    SnapshotConfiguration(name: "compact-empty", value: (Layout.compact, UserState.loggedOut)),
    SnapshotConfiguration(name: "regular-loaded", value: (Layout.regular, UserState.loggedIn)),
    SnapshotConfiguration(name: nil, value: (Layout.compact, UserState.loggedIn)),
  ])
  func tuple2(configuration: SnapshotConfiguration<(Layout, UserState)>) {
    #expectSnapshot(configuration) { layout, state in
      Text("\(String(describing: layout))-\(String(describing: state))")
    }
  }

  @Test(arguments: [
    SnapshotConfiguration(name: "compact-dark-scale1", value: (Layout.compact, UserState.loggedOut, 1.0)),
    SnapshotConfiguration(name: "regular-light-scale2", value: (Layout.regular, UserState.loggedIn, 2.0)),
  ])
  // swiftlint:disable:next large_tuple
  func tuple3(configuration: SnapshotConfiguration<(Layout, UserState, Double)>) {
    #expectSnapshot(configuration) { layout, state, scale in
      Text("\(String(describing: layout))-\(String(describing: state))-\(scale)")
    }
  }
}
#endif
