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
