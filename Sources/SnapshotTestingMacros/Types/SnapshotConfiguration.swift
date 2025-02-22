import Foundation

public struct SnapshotConfiguration<T: Sendable>: Sendable {
  let name: String?
  public let value: T

  public init(name: String?, value: T) {
    self.name = name
    self.value = value
  }

  /*
     When no configurations are passed we need type safety for makeValue(T).

     We need to pass an explicit Void type here.
     */public static var none: SnapshotConfiguration<Void> {
    .init(name: nil, value: ())
  }
}
