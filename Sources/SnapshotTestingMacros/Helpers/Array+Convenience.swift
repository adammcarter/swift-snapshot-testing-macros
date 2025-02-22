import Foundation

extension Array {
  func first<T>(as _: T.Type = T.self) -> T? {
    first(where: { $0 is T }) as? T
  }
}
