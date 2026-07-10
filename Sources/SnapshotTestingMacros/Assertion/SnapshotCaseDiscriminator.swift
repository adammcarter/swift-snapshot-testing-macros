import Foundation
import Testing

/// Derives a stable per-case discriminator from a parameterized `@Test(arguments:)` case.
///
/// An unnamed, non-`argument:` `#expectSnapshot` inside a parameterized test resolves its
/// reference name from `#function` alone, which is lexically identical across every argument
/// case. Because the attempt-scoping fix gives each case a fresh ``SnapshotExecutionContext``,
/// all cases would otherwise resolve — and overwrite — one reference file. Folding this
/// discriminator into the resolved name gives each case a distinct reference file, exactly the
/// way the `argument:` overload already distinguishes cases by deriving a name from the
/// argument value.
///
/// The discriminator is derived from the case's argument value(s) the same deterministic way
/// the configuration path derives its name (`String(describing:)`, normalized to a filesystem
/// path component). A non-parameterized case has no argument identity, so it yields `nil` and
/// the base name is preserved unchanged — keeping every existing non-parameterized reference
/// valid.
enum SnapshotCaseDiscriminator {
  /// Returns the normalized discriminator for `testCase`, or `nil` when the case is not
  /// parameterized (or its shape cannot be read, in which case naming safely falls back to the
  /// undiscriminated base name).
  static func value(for testCase: Test.Case?) -> String? {
    guard let testCase, let values = argumentValues(from: testCase) else {
      return nil
    }

    let component =
      values
      .map { normalizedComponent(from: $0) }
      .filter { !$0.isEmpty }
      .joined(separator: "-")

    return component.isEmpty ? nil : component
  }

  /// Normalizes one argument value into a filesystem-safe component, mirroring
  /// ``DerivedSnapshotNames``: tuples are described element-by-element so module/type
  /// qualification (and unstable per-process address markers) never leak into a reference file
  /// name, and everything else is described directly.
  private static func normalizedComponent(from value: Any) -> String {
    SnapshotNameNormalizer.folderComponent(from: description(of: value))
  }

  private static func description(of value: Any) -> String {
    let mirror = Mirror(reflecting: value)

    guard mirror.displayStyle == .tuple else {
      return String(describing: value)
    }

    return mirror.children
      .map { description(of: $0.value) }
      .joined(separator: "-")
  }

  /// Reflects the argument values out of a parameterized `Test.Case`.
  ///
  /// The current Swift Testing toolchain exposes neither `Test.Case.arguments` nor
  /// `Test.Case.id` publicly (or under `@_spi(ForToolsIntegrationOnly)`), so the values are
  /// read reflectively from the case's private `_kind` payload. The walk is defensive: any
  /// shape it does not recognize — a non-parameterized case, or a future layout change — yields
  /// `nil`, and naming degrades gracefully to the undiscriminated base name rather than
  /// trapping.
  private static func argumentValues(from testCase: Test.Case) -> [Any]? {
    let caseMirror = Mirror(reflecting: testCase)

    guard let kind = caseMirror.children.first(where: { $0.label == "_kind" })?.value else {
      return nil
    }

    let kindMirror = Mirror(reflecting: kind)

    guard
      kindMirror.displayStyle == .enum,
      let parameterized = kindMirror.children.first,
      parameterized.label == "parameterized"
    else {
      return nil
    }

    let payloadMirror = Mirror(reflecting: parameterized.value)

    guard let arguments = payloadMirror.children.first(where: { $0.label == "arguments" })?.value
    else {
      return nil
    }

    let argumentsMirror = Mirror(reflecting: arguments)

    guard argumentsMirror.displayStyle == .collection else {
      return nil
    }

    var values = [Any]()
    for argument in argumentsMirror.children {
      let argumentMirror = Mirror(reflecting: argument.value)

      guard let value = argumentMirror.children.first(where: { $0.label == "value" })?.value else {
        return nil
      }

      values.append(value)
    }

    return values.isEmpty ? nil : values
  }
}
