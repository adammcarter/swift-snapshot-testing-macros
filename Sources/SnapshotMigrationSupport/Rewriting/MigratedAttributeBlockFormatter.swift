import Foundation
import SwiftParser
import SwiftSyntax

/// Normalizes attribute trivia only for declarations changed by the migration.
struct MigratedAttributeBlockFormatter {
  func format(source: String, declarationKeywordOffsets: Set<Int>) -> String {
    guard !declarationKeywordOffsets.isEmpty else { return source }

    let tree = Parser.parse(source: source)
    let visitor = MigratedAttributeBlockVisitor(
      source: source,
      declarationKeywordOffsets: declarationKeywordOffsets
    )
    visitor.walk(tree)
    return apply(edits: visitor.edits, to: source)
  }

  private func apply(edits: [AttributeBlockEdit], to source: String) -> String {
    var output = source
    for edit in edits.sorted(by: { $0.startUTF8Offset > $1.startUTF8Offset }) {
      let start = index(atUTF8Offset: edit.startUTF8Offset, in: output)
      let end = index(atUTF8Offset: edit.endUTF8Offset, in: output)
      output.replaceSubrange(start..<end, with: edit.replacement)
    }
    return output
  }

  private func index(atUTF8Offset utf8Offset: Int, in source: String) -> String.Index {
    let clampedOffset = max(0, min(utf8Offset, source.utf8.count))
    let utf8Index = source.utf8.index(source.utf8.startIndex, offsetBy: clampedOffset)
    return String.Index(utf8Index, within: source) ?? source.endIndex
  }
}

private struct AttributeBlockEdit {
  let startUTF8Offset: Int
  let endUTF8Offset: Int
  let replacement: String
}

private final class MigratedAttributeBlockVisitor: SyntaxVisitor {
  private let source: String
  private let declarationKeywordOffsets: Set<Int>
  private let lineEnding: String

  private(set) var edits: [AttributeBlockEdit] = []

  init(source: String, declarationKeywordOffsets: Set<Int>) {
    self.source = source
    self.declarationKeywordOffsets = declarationKeywordOffsets
    self.lineEnding = source.contains("\r\n") ? "\r\n" : "\n"
    super.init(viewMode: .sourceAccurate)
  }

  override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    recordEdit(
      attributes: node.attributes,
      modifiers: node.modifiers,
      keyword: node.structKeyword
    )
    return .visitChildren
  }

  override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    recordEdit(
      attributes: node.attributes,
      modifiers: node.modifiers,
      keyword: node.classKeyword
    )
    return .visitChildren
  }

  override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
    recordEdit(
      attributes: node.attributes,
      modifiers: node.modifiers,
      keyword: node.actorKeyword
    )
    return .visitChildren
  }

  override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    recordEdit(
      attributes: node.attributes,
      modifiers: node.modifiers,
      keyword: node.enumKeyword
    )
    return .visitChildren
  }

  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    recordEdit(
      attributes: node.attributes,
      modifiers: node.modifiers,
      keyword: node.funcKeyword
    )
    return .visitChildren
  }

  private func recordEdit(
    attributes: AttributeListSyntax,
    modifiers: DeclModifierListSyntax,
    keyword: TokenSyntax
  ) {
    let keywordOffset = keyword.positionAfterSkippingLeadingTrivia.utf8Offset
    guard declarationKeywordOffsets.contains(keywordOffset) else { return }

    let attributeSyntaxes = attributes.compactMap { $0.as(AttributeSyntax.self) }
    guard !attributeSyntaxes.isEmpty, attributeSyntaxes.count == attributes.count else { return }

    let firstAttributeOffset = attributeSyntaxes[0].positionAfterSkippingLeadingTrivia.utf8Offset
    let nextTokenOffset = modifiers.first?.positionAfterSkippingLeadingTrivia.utf8Offset ?? keywordOffset
    let indentation = indentation(atUTF8Offset: firstAttributeOffset)

    var replacement = ""
    for (index, attribute) in attributeSyntaxes.enumerated() {
      let attributeStart = attribute.positionAfterSkippingLeadingTrivia.utf8Offset
      let attributeEnd = attribute.endPositionBeforeTrailingTrivia.utf8Offset
      replacement += sourceSlice(from: attributeStart, to: attributeEnd)

      let separatorEnd = index + 1 < attributeSyntaxes.count
        ? attributeSyntaxes[index + 1].positionAfterSkippingLeadingTrivia.utf8Offset
        : nextTokenOffset
      let rawSeparator = sourceSlice(from: attributeEnd, to: separatorEnd)
      guard let separator = normalizedSeparator(rawSeparator, indentation: indentation) else {
        return
      }
      replacement += separator
    }

    let original = sourceSlice(from: firstAttributeOffset, to: nextTokenOffset)
    guard replacement != original else { return }
    edits.append(
      AttributeBlockEdit(
        startUTF8Offset: firstAttributeOffset,
        endUTF8Offset: nextTokenOffset,
        replacement: replacement
      )
    )
  }

  /// Keeps comment-bearing trivia in order while removing whitespace-only separator lines.
  private func normalizedSeparator(_ rawSeparator: String, indentation: String) -> String? {
    let normalized = rawSeparator
      .replacingOccurrences(of: "\r\n", with: "\n")
      .replacingOccurrences(of: "\r", with: "\n")
    let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

    var result = ""
    var insideBlockComment = false
    for (index, line) in lines.enumerated() {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      guard !trimmed.isEmpty else { continue }
      guard isCommentLine(trimmed, insideBlockComment: &insideBlockComment) else { return nil }

      let preservedLine = trimmingTrailingWhitespace(line)
      if index == 0 {
        result += preservedLine
      } else {
        result += lineEnding + preservedLine
      }
    }
    guard !insideBlockComment else { return nil }

    result += lineEnding + indentation
    return result
  }

  private func isCommentLine(_ line: String, insideBlockComment: inout Bool) -> Bool {
    if insideBlockComment {
      if line.contains("*/") {
        insideBlockComment = false
      }
      return true
    }

    if line.hasPrefix("//") {
      return true
    }
    if line.hasPrefix("/*") {
      insideBlockComment = !line.contains("*/")
      return true
    }
    return false
  }

  private func indentation(atUTF8Offset utf8Offset: Int) -> String {
    let position = index(atUTF8Offset: utf8Offset)
    let lineStart = source[..<position].lastIndex(of: "\n").map { source.index(after: $0) } ?? source.startIndex
    return String(source[lineStart..<position].prefix { $0 == " " || $0 == "\t" })
  }

  private func sourceSlice(from startUTF8Offset: Int, to endUTF8Offset: Int) -> String {
    let start = index(atUTF8Offset: startUTF8Offset)
    let end = index(atUTF8Offset: endUTF8Offset)
    return String(source[start..<end])
  }

  private func index(atUTF8Offset utf8Offset: Int) -> String.Index {
    let clampedOffset = max(0, min(utf8Offset, source.utf8.count))
    let utf8Index = source.utf8.index(source.utf8.startIndex, offsetBy: clampedOffset)
    return String.Index(utf8Index, within: source) ?? source.endIndex
  }

  private func trimmingTrailingWhitespace(_ value: String) -> String {
    String(value.reversed().drop(while: { $0 == " " || $0 == "\t" }).reversed())
  }
}
