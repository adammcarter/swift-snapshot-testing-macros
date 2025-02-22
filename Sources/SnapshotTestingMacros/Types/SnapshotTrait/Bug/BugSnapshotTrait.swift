import Foundation
import Testing

public struct BugSnapshotTrait: SnapshotTrait {
  public typealias Comment = Testing.Comment

  let comment: Comment?
  let id: String?
  let url: String?

  public var debugDescription: String {
    let properties = [
      comment?.description,
      id,
      url,
    ]
    .compactMap { $0 }
    .joined(separator: ", ")

    return "bug: \(properties)"
  }

  init(
    comment: Comment? = nil,
    id: String? = nil,
    url: String? = nil
  ) {
    self.comment = comment
    self.id = id
    self.url = url
  }
}
