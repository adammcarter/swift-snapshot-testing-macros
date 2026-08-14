import SwiftUI
import Testing

@testable import SnapshotTestingMacros

/// Stable identity policy for snapshots used inside parameterized native tests.
///
/// The shipped Apple Testing module exposes `Test.Case.isParameterized`, but no supported case
/// argument values. Bare snapshots therefore fail closed; callers provide identity through
/// `argument:` or `SnapshotConfiguration` instead of relying on private-layout reflection or on an
/// assertion label that the runtime cannot prove is distinct for every case.
struct ParameterizedSnapshotIdentityTests {
  /// Covers both former collision classes: values that normalize to nothing and structurally
  /// distinct tuples that flatten to the same text. Neither may reach rendering under a shared
  /// undiscriminated reference.
  @Test(arguments: [("", ""), ("!!!", ""), ("a-b", "c"), ("a", "b-c")])
  func unnamedBareSnapshotInParameterizedTestRequiresExplicitIdentity(
    argument: (String, String)
  ) {
    withKnownIssue {
      #expectSnapshot(Text("\(argument.0)|\(argument.1)"))
    } matching: { issue in
      issue.comments.contains {
        $0.rawValue.contains("#expectSnapshot in a parameterized test has no stable case identity")
      }
    }
  }

  /// `named:` labels the assertion but does not carry the case value. A constant name can therefore
  /// collide across every case, and even a computed name cannot be verified without the private case
  /// arguments this design deliberately refuses to reflect.
  @Test(.record(.never), .theme(.light), arguments: ["alpha", "beta"])
  func explicitAssertionNameAloneCannotProveCaseIdentity(argument: String) {
    withKnownIssue {
      #expectSnapshot(Text(argument), named: "shared")
    } matching: { issue in
      issue.comments.contains {
        $0.rawValue.contains("#expectSnapshot in a parameterized test has no stable case identity")
      }
    }
  }

  /// Once `argument:` carries the case value, `named:` may still label the assertion without being
  /// responsible for case identity.
  @Test(.record(.never), .theme(.light), arguments: ["alpha"])
  func argumentIdentityAllowsAnAssertionName(argument: String) {
    withKnownIssue {
      #expectSnapshot(argument: argument, named: "shared") { Text($0) }
    } matching: { issue in
      issue.comments.contains { $0.rawValue.contains("No reference was found on disk") }
    }
  }
}
