import SwiftSyntax
import SwiftSyntaxMacros

func canContinueAfterSanityChecks(macroContext: SnapshotSuiteMacroContext) -> Bool {

  #warning("TODO: No error checks yet...")
  let passesErrorChecks = [
    true
  ]
  .allSatisfyTrue()

  guard passesErrorChecks else { return false }

  let passesWarningChecks = [
    checkSuiteAttribute(macroContext: macroContext)
  ]
  .allSatisfyTrue()

  guard passesWarningChecks else { return true }

  return true
}

// MARK: - Support

// MARK: Errors

#warning("Add errors??")

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
