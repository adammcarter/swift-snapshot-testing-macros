import SnapshotTestingMacros
import SwiftUI
import Testing

struct ExpectSnapshotDisplayNameTests {
  @Test("Profile card")
  func profileCard() {
    #expectSnapshot(Text("Display name stays in test output only"))
  }
}
