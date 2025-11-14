// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(member, names: arbitrary) public macro SnapshotSuite() = #externalMacro(module: "SnapshotsMacros", type: "SnapshotSuiteMacro")

@attached(member, names: arbitrary) public macro SnapshotSuite(
  _ displayName: String
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotSuiteMacro")

@attached(member, names: arbitrary) public macro SnapshotSuite(
  _ traits: any SnapshotSuiteTrait...
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotSuiteMacro")

@attached(member, names: arbitrary) public macro SnapshotSuite(
  _ displayName: String?,
  _ traits: any SnapshotSuiteTrait...
) = #externalMacro(module: "SnapshotsMacros", type: "SnapshotSuiteMacro")
