import Foundation

@discardableResult public func with<T>(
  _ value: T,
  _ update: (inout T) throws -> Void
) rethrows -> T {
  var newValue = value
  try update(&newValue)
  return newValue
}
