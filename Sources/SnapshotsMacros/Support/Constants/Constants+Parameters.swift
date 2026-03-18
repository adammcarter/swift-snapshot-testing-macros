import Foundation

extension Constants {
  enum Parameters {
    static let configuration = "configuration"
    static let configurations = "configurations"
    static let configurationValues = "configurationValues"
    static let configurationNameTransform = "configurationNameTransform"
  }
}

extension MacroToken.ParametersType {
  var configuration: MacroToken {
    .init(Constants.Parameters.configuration)
  }

  var configurations: MacroToken {
    .init(Constants.Parameters.configurations)
  }

  var configurationValues: MacroToken {
    .init(Constants.Parameters.configurationValues)
  }

  var configurationNameTransform: MacroToken {
    .init(Constants.Parameters.configurationNameTransform)
  }
}

extension MacroToken {
  static var Parameters: ParametersType { .init() }

  struct ParametersType: Sendable {}
}
