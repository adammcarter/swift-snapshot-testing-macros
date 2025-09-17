import Foundation
import SwiftSyntax

/// If adding to this, consider if you need to make use of the trait in `SnapshotTestingMacros.TraitsConfiguration`.
///
/// Generally, if you're just passing it to Swift Testing's @Test macro, you don't have to do anything.
///
/// But if the trait somehow affects how snapshots are taken, eg `.sizes()`, then you'll need to make use of it in `SnapshotTestingMacros.TraitsConfiguration`.
extension Constants {
  enum Trait: String, CaseIterable {
    case backgroundColor
    case bug
    case diffTool
    case disabled
    case enabled
    case padding
    case record
    case sizes
    case strategy
    case timeLimit
    case tags
    case theme
  }
}
