enum DerivedSnapshotNames {
  static func argumentName<Value: Sendable>(from value: Value) -> String {
    let normalized = SnapshotNameNormalizer.folderComponent(from: String(describing: value))
    return normalized.isEmpty ? "snapshot" : normalized
  }
}
