import SnapshotSupport
import SwiftDiagnostics
import SwiftSyntax

extension DiagnosticProtocol where Self == DiagnosticFactory {
  static func generalMessage(
    message: String,
    node: some SyntaxProtocol,
    fixIts: [FixIt] = []
  ) -> Diagnostic {
    .init(
      node: node,
      message: .generalMessage(message),
      fixIts: fixIts
    )
  }

  static func missingAttribute(
    _ attribute: String,
    suffix: String? = nil,
    node: AttributeSyntax,
    declaration: some DeclGroupSyntax
  ) -> Diagnostic {
    #warning("TODO: Whitespace fixes")

    // Trimming all the things doesn't fix this so it must be a non-trivia issue...
    // Debug in tests.

    let oldAttributes = declaration.attributes

    var newAttributes = oldAttributes
    newAttributes.insert(
      .attributeNamed(attribute),
      at: oldAttributes.startIndex
    )

    let declName = (declaration as? NamedDeclSyntax)?.name.text

    return .init(
      node: node,
      message: .missingAttribute(attribute, suffix: suffix),
      fixIts: [
        .replace(
          message: .missingAttribute(attribute, declName: declName),
          oldNode: oldAttributes,
          newNode: newAttributes
        )
      ]
    )
  }

  static func missingValidTests(
    node: AttributeSyntax,
    declaration: some DeclGroupSyntax
  ) -> Diagnostic {
    let oldNode = declaration

    #warning("TODO: Refactor this entire block to something nicer?")

    func makeNewNodeForFunction(
      returnType: String,
      typeDescription: String? = nil
    ) -> some DeclGroupSyntax {
      with(oldNode) {
        let contents = """
          @\(Constants.AttributeName.snapshotTest)
          func <#name#>() -> \(returnType) {
              <#return a \(typeDescription ?? returnType) here#>
          }
          """

        return $0
          .memberBlock
          .members
          .append(
            MemberBlockItemSyntax(
              leadingTrivia: .newline,
              decl: DeclSyntax(stringLiteral: contents)
            )
          )
      }
    }

    func makeNewNodeWithSnapshotTestAnnotationsOnViableFunctions() -> (Bool, some DeclGroupSyntax) {
      var didChange = false
      let newNode = with(oldNode) { node in
        let newMembers = node.memberBlock.members.map { member in
          if var functionDecl = member.decl.as(FunctionDeclSyntax.self), functionDecl.hasSupportedReturnType {
            with(member) { member in
              functionDecl.attributes.insert(
                .attribute(.init(stringLiteral: "@\(Constants.AttributeName.snapshotTest)")),
                at: functionDecl.attributes.startIndex
              )

              didChange = true

              member.decl = DeclSyntax(functionDecl)
            }
          }
          else {
            member
          }
        }

        node.memberBlock.members = MemberBlockItemListSyntax {
          newMembers
        }
      }

      return (didChange, newNode)
    }

    var functionReplacements: [FixIt] = []

    functionReplacements += [
      .replace(
        message: .generalMessage("Add a function to make a SwiftUI view."),
        oldNode: oldNode,
        newNode: makeNewNodeForFunction(returnType: "some View", typeDescription: "SwiftUI view")
      )
    ]

    functionReplacements += [
      .replace(
        message: .generalMessage("Add a function to make a UIView."),
        oldNode: oldNode,
        newNode: makeNewNodeForFunction(returnType: "UIView")
      ),
      .replace(
        message: .generalMessage("Add a function to make a UIViewController."),
        oldNode: oldNode,
        newNode: makeNewNodeForFunction(returnType: "UIViewController")
      ),
    ]

    functionReplacements += [
      .replace(
        message: .generalMessage("Add a function to make a NSView."),
        oldNode: oldNode,
        newNode: makeNewNodeForFunction(returnType: "NSView")
      ),
      .replace(
        message: .generalMessage("Add a function to make a NSViewController."),
        oldNode: oldNode,
        newNode: makeNewNodeForFunction(returnType: "NSViewController")
      ),
    ]

    #warning("TODO: Use optional instead")
    let (didChange, newFunctionsWithAnnotationsNode) = makeNewNodeWithSnapshotTestAnnotationsOnViableFunctions()

    if didChange {
      functionReplacements += [
        .replace(
          message: .generalMessage("Add @\(Constants.AttributeName.snapshotTest) annotations to viable functions."),
          oldNode: oldNode,
          newNode: newFunctionsWithAnnotationsNode
        )
      ]
    }

    return .init(
      node: node,
      message: .generalMessage("Missing valid snapshot suite tests."),
      fixIts: [
        .replace(
          message: .generalMessage("Remove the @\(Constants.AttributeName.snapshotSuite) attribute."),
          oldNode: oldNode,
          newNode: with(oldNode) { $0.attributes.removingFirstAttributeNamed(Constants.AttributeName.snapshotSuite) }
        )
      ] + functionReplacements
    )
  }
}

extension DiagnosticMessage where Self == DiagnosticWarningMessage {
  static func generalMessage(
    _ message: String
  ) -> DiagnosticWarningMessage {
    .init(message: message)
  }

  static func missingAttribute(
    _ attribute: String,
    suffix: String? = nil
  ) -> DiagnosticWarningMessage {
    let suffix = suffix ?? ""

    return .init(message: "Add @\(attribute) attribute to the test suite\(suffix).")
  }
}

extension FixItMessage where Self == FixItWarning {
  static func generalMessage(
    _ message: String
  ) -> FixItWarning {
    .init(message: message)
  }

  static func missingAttribute(
    _ attribute: String,
    declName: String?
  ) -> FixItWarning {
    let name = declName.flatMap { " to \($0)" } ?? ""

    return .init(message: "Add @\(attribute) attribute\(name)")
  }
}

// MARK: - Diagnostic types

protocol DiagnosticProtocol {
  var node: SyntaxProtocol { get }
  var position: AbsolutePosition? { get }
  var message: DiagnosticMessage { get }
  var highlights: [Syntax]? { get }
  var notes: [Note] { get }
  var fixIts: [FixIt] { get }
}

struct DiagnosticFactory: DiagnosticProtocol {
  let node: SyntaxProtocol
  let position: AbsolutePosition?
  let message: DiagnosticMessage
  let highlights: [Syntax]?
  let notes: [Note]
  let fixIts: [FixIt]

  init(
    node: SyntaxProtocol,
    position: AbsolutePosition? = nil,
    message: DiagnosticMessage,
    highlights: [Syntax]? = nil,
    notes: [Note] = [],
    fixIts: [FixIt]
  ) {
    self.node = node
    self.position = position
    self.message = message
    self.highlights = highlights
    self.notes = notes
    self.fixIts = fixIts
  }
}

struct DiagnosticWarningMessage: DiagnosticMessage {
  let message: String
  let severity: DiagnosticSeverity = .warning

  var diagnosticID: MessageID {
    .init(domain: "SnapshotsMacro", id: message)
  }
}

struct FixItWarning: FixItMessage {
  var message: String

  var fixItID: MessageID {
    .init(domain: "SnapshotsMacro", id: message)
  }
}
