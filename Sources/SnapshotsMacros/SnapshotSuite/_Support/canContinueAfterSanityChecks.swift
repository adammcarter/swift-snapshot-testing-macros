import SwiftSyntax
import SwiftSyntaxMacros

func canContinueAfterSanityChecks(macroContext: SnapshotSuiteMacroContext) -> Bool {
  guard checkNotAnExtension(macroContext: macroContext) else { return false }

  checkDisplayNameIsRepresentable(macroContext: macroContext)

  _ = checkSuiteAttribute(macroContext: macroContext)

  return true
}

// MARK: - Support

// MARK: Errors

/// `@SnapshotSuite` on an extension has never generated a runnable suite: the peer macro
/// cannot name the extended type, so the member expansion references generator containers
/// that are never emitted. Reject it outright instead of emitting broken code.
private func checkNotAnExtension(macroContext: SnapshotSuiteMacroContext) -> Bool {
  guard macroContext.declaration.is(ExtensionDeclSyntax.self) else { return true }

  macroContext.context.diagnose(
    DiagnosticFactory.generalErrorMessage(
      message: "'@SnapshotSuite' cannot be applied to extensions. Apply it to the type declaration instead.",
      node: macroContext.node
    )
  )

  return false
}

/// An interpolated display name cannot be evaluated at expansion time and previously fell back
/// to the type name without any indication. Reject it so the user either makes the literal
/// static or removes it.
private func checkDisplayNameIsRepresentable(macroContext: SnapshotSuiteMacroContext) {
  guard unrepresentableDisplayNameArgument(in: macroContext.node) != nil else {
    return
  }

  macroContext.context.diagnose(
    DiagnosticFactory.generalErrorMessage(
      message: "A '@SnapshotSuite' display name must be a simple string literal; interpolation is not supported.",
      node: macroContext.node
    )
  )
}

// MARK: Warnings

private func checkSuiteAttribute(macroContext: SnapshotSuiteMacroContext) -> Bool {
  let isSnapshotTest = macroContext
    .declaration
    .attributes
    .hasAttributeNamed(Constants.AttributeName.snapshotTest)

  guard isSnapshotTest == false else { return true }

  return attributeIsPresent(
    attributeName: Constants.AttributeName.suite,
    diagnosticSuffix: " to easily run tests from Xcode",
    macroContext: macroContext
  )
}

// MARK: - Helpers

private func attributeIsPresent(
  attributeName: String,
  diagnosticSuffix: String? = nil,
  macroContext: SnapshotSuiteMacroContext
) -> Bool {
  let hasAttribute = macroContext
    .declaration
    .attributes
    .hasAttributeNamed(attributeName)

  guard hasAttribute else {
    macroContext.context.diagnose(
      DiagnosticFactory.missingAttribute(
        attributeName,
        suffix: diagnosticSuffix,
        node: macroContext.node,
        declaration: macroContext.declaration
      )
    )

    return false
  }

  return true
}
