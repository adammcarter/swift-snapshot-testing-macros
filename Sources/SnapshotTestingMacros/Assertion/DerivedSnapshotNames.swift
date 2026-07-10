enum DerivedSnapshotNames {
  static func argumentName<Value: Sendable>(from value: Value) -> String {
    let normalized = SnapshotNameNormalizer.folderComponent(from: description(of: value))
    return normalized.isEmpty ? "snapshot" : normalized
  }

  /*
   Tuples are described per element: `String(describing:)` prints a bare value unqualified
   ("compact") but qualifies every element of a tuple with its module and type
   ("(MyModule.Layout.compact, MyModule.UserState.loggedIn)") — and embeds unstable
   "(unknown context at 0x...)" markers for non-public types — so describing the tuple as a
   whole would bake module/type names (or worse, per-process addresses) into reference file
   names. Renaming the test module or moving the enum would then orphan every derived tuple
   reference without any change to the values themselves.
   */
  private static func description(of value: Any) -> String {
    let mirror = Mirror(reflecting: value)

    guard mirror.displayStyle == .tuple else {
      return String(describing: value)
    }

    return mirror.children
      .map { description(of: $0.value) }
      .joined(separator: "-")
  }
}
