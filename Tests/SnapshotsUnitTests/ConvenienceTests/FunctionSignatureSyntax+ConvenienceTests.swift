#if os(macOS)
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing
import XCTest

@testable import SnapshotsMacros

struct FunctionSignatureSyntaxConvenienceTests {
  @Test(
    arguments: [
      (
        """
        func a() { }
        """,
        false
      ),
      (
        """
        func a() async { }
        """,
        true
      ),
      (
        """
        func a() async throws { }
        """,
        true
      ),
    ]
  )
  func isAsync(
    input: String,
    expected: Bool
  ) throws {
    let decl = try makeFunctionDecl(from: input)

    #expect(decl.signature.isAsync == expected)
  }

  @Test(
    arguments: [
      (
        """
        func a() { }
        """,
        false
      ),
      (
        """
        func a() throws { }
        """,
        true
      ),
      (
        """
        func a() async throws { }
        """,
        true
      ),
    ]
  )
  func isThrows(
    input: String,
    expected: Bool
  ) throws {
    let decl = try makeFunctionDecl(from: input)

    #expect(decl.signature.isThrows == expected)
  }

  @Test
  func parameterClauseAsTuple() throws {
    let decl = try makeFunctionDecl(from: "func a(x: Int, y: String) {}")
    let tuple = decl.signature.parameterClauseAsTuple

    #expect(tuple.count == 2)
    #expect(tuple.first?.type.description == "Int")
    #expect(tuple.last?.type.description == "String")
  }
}

private func makeFunctionDecl(
  from string: String
) throws -> FunctionDeclSyntax {
  try XCTUnwrap(FunctionDeclSyntax(DeclSyntax(stringLiteral: string)))
}
#endif
