import SnapshotTestingMacros
import SwiftUI
import Testing

enum CountState: Int, CaseIterable, Sendable {
  case zero
  case one
}

struct ExpectSnapshotArgumentIntegrationTests {
  @Test(arguments: CountState.allCases)
  func derivedArgumentName(state: CountState) {
    #expectSnapshot(argument: state) { state in
      Text("state-\(state.rawValue)")
    }
  }
}
