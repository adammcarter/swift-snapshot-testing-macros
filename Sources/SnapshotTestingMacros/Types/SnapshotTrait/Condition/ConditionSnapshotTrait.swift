import Foundation
import Testing

public struct ConditionSnapshotTrait: SnapshotTrait {
  public typealias ConditionHandler = () async throws -> Bool
  public typealias Comment = Testing.Comment

  private let condition: ConditionHandler
  private let conditionDescription: String

  public var debugDescription: String {
    "condition: \(conditionDescription)"
  }

  init(
    condition: @escaping ConditionHandler,
    conditionDescription: String = #function
  ) {
    self.condition = condition
    self.conditionDescription = conditionDescription
  }

  enum ConditionError: Error {
    case failed(Error)

    var localizedDescription: String {
      switch self {
        case .failed(let error): error.localizedDescription
      }
    }
  }
}
