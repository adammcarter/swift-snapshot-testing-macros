import SwiftUI

/*
 The runtime landing pads for `#expectSnapshot`'s expansion. Two attributes on this surface
 are load-bearing rather than decorative:

 - `@ViewBuilder` on the SwiftUI builders has to be *here*, not only on the macro declaration:
   the expansion re-type-checks its argument against these functions, so a builder attribute
   that lives only on the macro moves the failure into the expansion buffer instead of fixing
   it. It is what lets a snapshot body hold sibling views, `if` / `else`, `switch` and
   `ForEach` like any other SwiftUI closure. A body containing an explicit `return` opts out
   of the transform (SE-0289), which is what keeps `{ await …; return SomeView() }` working.

 - `@_disfavoredOverload` on the UIKit/AppKit builders is what keeps the SwiftUI builders
   usable. Every family's builder is `@escaping @MainActor`, and the macro expands to one
   argument label set for all of them, so a `@ViewBuilder` body that the platform overloads
   cannot possibly accept still ties with them ("Ambiguous use of '__expectSnapshot(…)'").
   Disfavouring the platform overloads breaks the tie in the only direction that can type
   check; it cannot change which overload a `SnapshotView` or `SnapshotViewController` body
   reaches, because no SwiftUI overload is viable for those.

 There is deliberately no positional direct-value landing pad. `#expectSnapshot(someView)` is
 spliced into `makeValue:` as a closure literal, so the value's effects belong to the closure
 and the compiler selects the sync / `throws` / `async` / `async throws` overload itself. The
 `@autoclosure` overloads this replaced could not express `async` at all, and needed a
 `throwingMarker: ()` argument synthesized from a syntactic `try` check in the macro to reach
 their throwing halves — a mechanism that silently missed `try` anywhere but the root of the
 expression. See `ExpectSnapshotMacro` for the full account.
 */

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot(
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor () -> SnapshotView
) {
  ExpectSnapshotAdapter.run(
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot(
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor () -> SnapshotViewController
) {
  ExpectSnapshotAdapter.run(
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot(
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor () throws -> SnapshotView
) throws {
  try ExpectSnapshotAdapter.run(
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot(
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor () throws -> SnapshotViewController
) throws {
  try ExpectSnapshotAdapter.run(
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot(
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor () async -> SnapshotView
) async {
  await ExpectSnapshotAdapter.run(
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot(
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor () async -> SnapshotViewController
) async {
  await ExpectSnapshotAdapter.run(
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot(
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor () async throws -> SnapshotView
) async throws {
  try await ExpectSnapshotAdapter.run(
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot(
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor () async throws -> SnapshotViewController
) async throws {
  try await ExpectSnapshotAdapter.run(
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View>(
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  @ViewBuilder makeValue: @escaping @MainActor () -> V
) {
  ExpectSnapshotAdapter.run(
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View>(
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  @ViewBuilder makeValue: @escaping @MainActor () throws -> V
) throws {
  try ExpectSnapshotAdapter.run(
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View>(
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  @ViewBuilder makeValue: @escaping @MainActor () async -> V
) async {
  await ExpectSnapshotAdapter.run(
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View>(
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  @ViewBuilder makeValue: @escaping @MainActor () async throws -> V
) async throws {
  try await ExpectSnapshotAdapter.run(
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  @ViewBuilder makeValue: @escaping @MainActor (Argument) -> V
) {
  ExpectSnapshotAdapter.run(
    argument: argument,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  @ViewBuilder makeValue: @escaping @MainActor (Argument) throws -> V
) throws {
  try ExpectSnapshotAdapter.run(
    argument: argument,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  @ViewBuilder makeValue: @escaping @MainActor (Argument) async -> V
) async {
  await ExpectSnapshotAdapter.run(
    argument: argument,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  @ViewBuilder makeValue: @escaping @MainActor (Argument) async throws -> V
) async throws {
  try await ExpectSnapshotAdapter.run(
    argument: argument,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (Argument) -> SnapshotView
) {
  ExpectSnapshotAdapter.run(
    argument: argument,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (Argument) -> SnapshotViewController
) {
  ExpectSnapshotAdapter.run(
    argument: argument,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (Argument) throws -> SnapshotView
) throws {
  try ExpectSnapshotAdapter.run(
    argument: argument,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (Argument) throws -> SnapshotViewController
) throws {
  try ExpectSnapshotAdapter.run(
    argument: argument,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (Argument) async -> SnapshotView
) async {
  await ExpectSnapshotAdapter.run(
    argument: argument,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (Argument) async -> SnapshotViewController
) async {
  await ExpectSnapshotAdapter.run(
    argument: argument,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (Argument) async throws -> SnapshotView
) async throws {
  try await ExpectSnapshotAdapter.run(
    argument: argument,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<Argument: Sendable>(
  argument: Argument,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (Argument) async throws -> SnapshotViewController
) async throws {
  try await ExpectSnapshotAdapter.run(
    argument: argument,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  @ViewBuilder makeValue: @escaping @MainActor (ConfigurationValue) -> V
) {
  ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  @ViewBuilder makeValue: @escaping @MainActor (ConfigurationValue) throws -> V
) throws {
  try ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  @ViewBuilder makeValue: @escaping @MainActor (ConfigurationValue) async -> V
) async {
  await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  @ViewBuilder makeValue: @escaping @MainActor (ConfigurationValue) async throws -> V
) async throws {
  try await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (ConfigurationValue) -> SnapshotView
) {
  ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (ConfigurationValue) -> SnapshotViewController
) {
  ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (ConfigurationValue) throws -> SnapshotView
) throws {
  try ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (ConfigurationValue) throws -> SnapshotViewController
) throws {
  try ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (ConfigurationValue) async -> SnapshotView
) async {
  await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (ConfigurationValue) async -> SnapshotViewController
) async {
  await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (ConfigurationValue) async throws -> SnapshotView
) async throws {
  try await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<ConfigurationValue: Sendable>(
  _ configuration: SnapshotConfiguration<ConfigurationValue>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (ConfigurationValue) async throws -> SnapshotViewController
) async throws {
  try await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  @ViewBuilder makeValue: @escaping @MainActor (A, B) -> V
) {
  ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  @ViewBuilder makeValue: @escaping @MainActor (A, B) throws -> V
) throws {
  try ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  @ViewBuilder makeValue: @escaping @MainActor (A, B) async -> V
) async {
  await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  @ViewBuilder makeValue: @escaping @MainActor (A, B) async throws -> V
) async throws {
  try await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  @ViewBuilder makeValue: @escaping @MainActor (A, B, C) -> V
) {
  ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (A, B) -> SnapshotView
) {
  ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (A, B) -> SnapshotViewController
) {
  ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (A, B) throws -> SnapshotView
) throws {
  try ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (A, B) throws -> SnapshotViewController
) throws {
  try ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (A, B) async -> SnapshotView
) async {
  await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (A, B) async -> SnapshotViewController
) async {
  await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (A, B) async throws -> SnapshotView
) async throws {
  try await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<A: Sendable, B: Sendable>(
  _ configuration: SnapshotConfiguration<(A, B)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (A, B) async throws -> SnapshotViewController
) async throws {
  try await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (A, B, C) -> SnapshotView
) {
  ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (A, B, C) -> SnapshotViewController
) {
  ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (A, B, C) throws -> SnapshotView
) throws {
  try ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (A, B, C) throws -> SnapshotViewController
) throws {
  try ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (A, B, C) async -> SnapshotView
) async {
  await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (A, B, C) async -> SnapshotViewController
) async {
  await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (A, B, C) async throws -> SnapshotView
) async throws {
  try await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
@_disfavoredOverload
// swiftlint:disable:next identifier_name
public func __expectSnapshot<A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  makeValue: @escaping @MainActor (A, B, C) async throws -> SnapshotViewController
) async throws {
  try await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  @ViewBuilder makeValue: @escaping @MainActor (A, B, C) throws -> V
) throws {
  try ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  @ViewBuilder makeValue: @escaping @MainActor (A, B, C) async -> V
) async {
  await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}

@_documentation(visibility: private)
// swiftlint:disable:next identifier_name
public func __expectSnapshot<V: View, A: Sendable, B: Sendable, C: Sendable>(
  // swiftlint:disable:next large_tuple
  _ configuration: SnapshotConfiguration<(A, B, C)>,
  named: String? = nil,
  function: StaticString = #function,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  @ViewBuilder makeValue: @escaping @MainActor (A, B, C) async throws -> V
) async throws {
  try await ExpectSnapshotAdapter.run(
    configuration: configuration,
    named: named,
    function: function,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column,
    makeValue: makeValue
  )
}
