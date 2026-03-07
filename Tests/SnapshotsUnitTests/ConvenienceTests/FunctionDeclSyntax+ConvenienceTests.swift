#if os(macOS)
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing
import XCTest

@testable import SnapshotsMacros

struct FunctionDeclSyntaxConvenienceTests {

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

    #expect(try makeFunctionDecl(from: input).isAsync == expected)
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

    #expect(try makeFunctionDecl(from: input).isThrows == expected)
  }

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
        false
      ),
      (
        """
        @SnapshotTest
        func a() -> some View { }
        """,
        true
      ),
      (
        """
        @SnapshotTest
        func a() -> NSViewController { }
        """,
        true
      ),
      (
        """
        @SnapshotTest
        func a() -> NSView { }
        """,
        true
      ),
      (
        """
        @SnapshotTest
        func a() -> UIViewController { }
        """,
        true
      ),
      (
        """
        @SnapshotTest
        func a() -> UIView { }
        """,
        true
      ),
      (
        """
        func a() -> some View { }
        """,
        false
      ),
      (
        """
        @SnapshotTest
        func a() { }
        """,
        false
      ),
    ]
  )
  func isSupportedForSnapshots(
    input: String,
    expected: Bool
  ) throws {

    #expect(try makeFunctionDecl(from: input).isSupportedForSnapshots == expected)
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

  @Test(
    arguments: [
      (
        """
        func a() -> some View { }
        """,
        true
      ),
      (
        """
        func a() -> NSViewController { }
        """,
        true
      ),
      (
        """
        func a() -> NSView { }
        """,
        true
      ),
      (
        """
        func a() -> UIViewController { }
        """,
        true
      ),
      (
        """
        func a() -> UIView { }
        """,
        true
      ),
      (
        """
        func a() -> String { }
        """,
        false
      ),
    ]
  )
  func hasSupportedReturnType(
    input: String,
    expected: Bool
  ) throws {

    #expect(try makeFunctionDecl(from: input).hasSupportedReturnType == expected)
  }

  @Test(
    arguments: [
      (
        """
        @SnapshotTest
        func a() { }
        """,
        "SnapshotTest",
        true
      ),
      (
        """
        @Test
        func a() { }
        """,
        "SnapshotTest",
        false
      ),
      (
        """
        func a() { }
        """,
        "SnapshotTest",
        false
      ),
    ]
  )
  func hasAttributeNamed(
    input: String,
    name: String,
    expected: Bool
  ) throws {

    #expect(try makeFunctionDecl(from: input).hasAttributeNamed(name) == expected)
  }

  @Test(
    arguments: [
      (
        """
        @SnapshotTest
        func a() { }
        """,
        "SnapshotTest",
        true
      ),
      (
        """
        @Test
        func a() { }
        """,
        "SnapshotTest",
        false
      ),
    ]
  )
  func firstAttributeNamed(
    input: String,
    name: String,
    expected: Bool
  ) throws {
    let decl = try makeFunctionDecl(from: input)
    let attr = decl.firstAttributeNamed(name)

    #expect((attr != nil) == expected)
  }
}

private func makeFunctionDecl(
  from string: String
) throws -> FunctionDeclSyntax {
  try XCTUnwrap(FunctionDeclSyntax(DeclSyntax(stringLiteral: string)))
}
#endif
