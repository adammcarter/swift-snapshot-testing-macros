#if os(macOS)
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing
import XCTest

@testable import SnapshotsMacros

@Suite
struct FunctionDeclSyntaxConvenienceTests {

  @Test(
    arguments: [
      (
        """
        static func a() { }
        """,
        true
      ),
      (
        """
        static    func a() { }
        """,
        true
      ),
      (
        """
        func a() { }
        """,
        false
      ),
    ]
  )
  func isStatic(
    input: String,
    expected: Bool
  ) throws {
    #expect(try makeFunctionDecl(from: input).isStatic == expected)
  }

  @Test(
    arguments: [
      (
        """
        func a() { }
        """,
        "",
        false
      ),
      (
        """
        func a() -> Void { }
        """,
        "Void",
        true
      ),
      (
        """
        func a() -> () { }
        """,
        "()",
        true
      ),
      (
        """
        func a() -> String { }
        """,
        "String",
        true
      ),
      (
        """
        func a() -> some View { }
        """,
        "some View",
        true
      ),
      (
        """
        func a() -> Foundation.String { }
        """,
        "Foundation.String",
        true
      ),
      (
        """
        func a() ->     Int { }
        """,
        "Int",
        true
      ),
    ]
  )
  func hasReturnType(
    input: String,
    type: String,
    expected: Bool
  ) throws {
    #expect(try makeFunctionDecl(from: input).hasReturnType(type) == expected)
  }
}

private func makeFunctionDecl(
  from string: String
) throws -> FunctionDeclSyntax {
  try XCTUnwrap(FunctionDeclSyntax(DeclSyntax(stringLiteral: string)))
}
#endif
