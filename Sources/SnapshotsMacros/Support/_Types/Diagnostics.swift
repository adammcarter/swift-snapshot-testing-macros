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

  static func generalErrorMessage(
    message: String,
    node: some SyntaxProtocol,
    fixIts: [FixIt] = []
  ) -> Diagnostic {
    .init(
      node: node,
      message: .generalErrorMessage(message),
      fixIts: fixIts
    )
  }

  static func missingAttribute(
    _ attribute: String,
    suffix: String? = nil,
    node: AttributeSyntax,
    declaration: some DeclGroupSyntax
  ) -> Diagnostic {
    let oldAttributes = declaration.attributes

    /*
     Prepend the new attribute on its own line. The inserted attribute takes the position the
     old first attribute held (inheriting its leading trivia), and the old first attribute is
     pushed onto the next line. Giving only the inserted attribute a `.newline` leaves the
     displaced one with empty leading trivia, which renders as `@Suite@MainActor` — two
     attributes fused into invalid Swift. Reusing the old first attribute's own indentation
     keeps the fix correct for nested, indented declarations too.
     */
    var elements = Array(oldAttributes)
    let newAttributes: AttributeListSyntax

    if let firstLeadingTrivia = elements.first?.leadingTrivia {
      elements[0] = elements[0].with(\.leadingTrivia, .newline + firstLeadingTrivia.lineIndentation)
      elements.insert(
        .attributeNamed(attribute).with(\.leadingTrivia, firstLeadingTrivia),
        at: 0
      )
      newAttributes = AttributeListSyntax(elements)
    }
    else {
      newAttributes = AttributeListSyntax {
        .attributeNamed(attribute)
      }
    }

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

    // Helper to generate fix-its for adding functions
    func fixIt(
      message: String,
      newNode: some DeclGroupSyntax
    ) -> FixIt {
      .replace(
        message: .generalMessage(message),
        oldNode: oldNode,
        newNode: newNode
      )
    }

    var functionReplacements: [FixIt] = []

    functionReplacements.append(
      fixIt(
        message: "Add a function to make a SwiftUI view.",
        newNode: oldNode.appendingSnapshotTestFunction(
          returnType: "some View",
          typeDescription: "SwiftUI view"
        )
      )
    )

    functionReplacements.append(contentsOf: [
      fixIt(
        message: "Add a function to make a UIView.",
        newNode: oldNode.appendingSnapshotTestFunction(returnType: "UIView")
      ),
      fixIt(
        message: "Add a function to make a UIViewController.",
        newNode: oldNode.appendingSnapshotTestFunction(returnType: "UIViewController")
      ),
    ])

    functionReplacements.append(contentsOf: [
      fixIt(
        message: "Add a function to make a NSView.",
        newNode: oldNode.appendingSnapshotTestFunction(returnType: "NSView")
      ),
      fixIt(
        message: "Add a function to make a NSViewController.",
        newNode: oldNode.appendingSnapshotTestFunction(returnType: "NSViewController")
      ),
    ])

    if let newFunctionsWithAnnotationsNode = oldNode.applyingSnapshotTestAnnotationsToViableFunctions() {
      functionReplacements.append(
        fixIt(
          message: "Add @\(Constants.AttributeName.snapshotTest) annotations to viable functions.",
          newNode: newFunctionsWithAnnotationsNode
        )
      )
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

private extension Trivia {
  /// The run of horizontal whitespace after the final line break — the indentation a line
  /// inserted after this trivia should reuse so it lines up with what preceded it.
  var lineIndentation: Trivia {
    var indentation: [TriviaPiece] = []

    for piece in pieces {
      switch piece {
      case .spaces, .tabs:
        indentation.append(piece)
      default:
        // A newline (or any non-space piece) starts the indentation run over: only the
        // whitespace since the last line break is indentation.
        indentation.removeAll()
      }
    }

    return Trivia(pieces: indentation)
  }
}

private extension DeclGroupSyntax {
  func appendingSnapshotTestFunction(
    returnType: String,
    typeDescription: String? = nil
  ) -> some DeclGroupSyntax {
    var newNode = self
    let contents = """
      @\(Constants.AttributeName.snapshotTest)
      func <#name#>() -> \(returnType) {
          <#return a \(typeDescription ?? returnType) here#>
      }
      """

    newNode.memberBlock.members.append(
      MemberBlockItemSyntax(
        leadingTrivia: .newline,
        decl: DeclSyntax(stringLiteral: contents)
      )
    )

    return newNode
  }

  func applyingSnapshotTestAnnotationsToViableFunctions() -> (some DeclGroupSyntax)? {
    var didChange = false
    var newNode = self

    let newMembers = newNode.memberBlock.members.map { member in
      if var functionDecl = member.decl.as(FunctionDeclSyntax.self), functionDecl.hasSupportedReturnType {
        functionDecl.attributes.insert(
          .attribute(.init(stringLiteral: "@\(Constants.AttributeName.snapshotTest)")),
          at: functionDecl.attributes.startIndex
        )

        didChange = true

        var newMember = member
        newMember.decl = DeclSyntax(functionDecl)
        return newMember
      }
      else {
        return member
      }
    }

    newNode.memberBlock.members = MemberBlockItemListSyntax {
      newMembers
    }

    return didChange ? newNode : nil
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

extension DiagnosticMessage where Self == DiagnosticErrorMessage {
  static func generalErrorMessage(
    _ message: String
  ) -> DiagnosticErrorMessage {
    .init(message: message)
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

struct DiagnosticErrorMessage: DiagnosticMessage {
  let message: String
  let severity: DiagnosticSeverity = .error

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
