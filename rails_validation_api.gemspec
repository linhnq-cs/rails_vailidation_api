require_relative "lib/rails_validation_api/version"

Gem::Specification.new do |spec|
  spec.name          = "rails_validation_api"
  spec.version       = RailsValidationApi::VERSION
  spec.authors       = ["Linh Nguyen Quang"]
  spec.email         = ["linhnq@gmail.com"]
  spec.summary       = "Enhanced parameter validation system for Rails APIs with automatic controller integration"
  spec.description   = "Rails Validation API provides a powerful for validating request parameters in Rails applications. Features include automatic validator loading based on controller/action names, nested parameter validation, custom error handling, and seamless integration with Rails controllers through concerns. Perfect for API applications requiring robust parameter validation with minimal boilerplate code."
  spec.homepage      = "https://github.com/linhnq-cs/rails_vailidation_api"
  spec.license       = "MIT"
  spec.files         = Dir["lib/**/*.rb"] + Dir["exe/**/*"]
  spec.require_paths = ["lib"]
  spec.executables = ["rails_validation_api"]
  spec.bindir      = "exe"
  spec.metadata["bug_tracker_uri"] = "https://github.com/linhnq-cs/rails_vailidation_api/issues"
  spec.metadata["funding_uri"] = "https://www.buymeacoffee.com/linh236"

  spec.add_dependency "activesupport", ">= 5.0"
  spec.add_dependency "rails_param", "~> 1.3.1"
  spec.add_dependency "activemodel", ">= 5.0"
  spec.add_dependency "railties", ">= 5.0"

  spec.add_development_dependency "debug", "~> 1.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
