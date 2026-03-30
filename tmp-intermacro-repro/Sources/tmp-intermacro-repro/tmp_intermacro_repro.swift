@attached(member, names: named(generatedByMacro))
public macro GenerateTest() = #externalMacro(
  module: "SwiftTestingInterMacroReproMacros",
  type: "GenerateTestMacro"
)
