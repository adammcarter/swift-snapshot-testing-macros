import Foundation
import SwiftSyntax

extension TokenSyntax {
  var identifierDisplayName: String {
    unescapedIdentifierText
  }

  var generatedIdentifierComponent: String {
    let source = unescapedIdentifierText
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))

    var outputScalars: [UnicodeScalar] = []
    var previousWasUnderscore = false

    for scalar in source.unicodeScalars {
      if allowed.contains(scalar) {
        outputScalars.append(scalar)
        previousWasUnderscore = scalar == "_"
      }
      else if previousWasUnderscore == false {
        outputScalars.append("_")
        previousWasUnderscore = true
      }
    }

    var output = String(String.UnicodeScalarView(outputScalars))

    if output.isEmpty {
      output = "_"
    }

    if let first = output.unicodeScalars.first, CharacterSet.decimalDigits.contains(first) {
      output = "_" + output
    }

    if output != source {
      output += "_" + stableHashSuffix(for: source)
    }

    return output
  }

  private func stableHashSuffix(for string: String) -> String {
    var hash: UInt64 = 14_695_981_039_346_656_037

    for byte in string.utf8 {
      hash ^= UInt64(byte)
      hash &*= 1_099_511_628_211
    }

    let hex = String(hash, radix: 16, uppercase: false)
    let paddedHex = String(repeating: "0", count: max(0, 16 - hex.count)) + hex

    return String(paddedHex.suffix(8))
  }

  private var unescapedIdentifierText: String {
    let value = text

    guard value.count >= 2, value.hasPrefix("`"), value.hasSuffix("`") else {
      return value
    }

    return String(value.dropFirst().dropLast())
  }
}
