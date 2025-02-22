import Foundation
import Testing

public struct TagSnapshotTrait: SnapshotTrait {
  public typealias Tag = Testing.Tag

  let tags: [Tag]

  public var debugDescription: String {
    let tags = tags.map(\.description).joined(separator: ", ")

    return "tag: \(tags)"
  }

  init(tags: [Tag]) {
    self.tags = tags
  }
}
