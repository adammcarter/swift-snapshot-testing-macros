import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main struct SnapshotsPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    SnapshotSuiteMacro.self,
    SnapshotTestMacro.self,
  ]
}
