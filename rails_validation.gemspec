require_relative "lib/rails_validation/version"

Gem::Specification.new do |spec|
  spec.name          = "rails_validation"
  spec.version       = RailsValidation::VERSION
  spec.authors       = ["Linh Nguyen Quang"]
  spec.email         = ["linhnq@gmail.com"]
  spec.summary       = "Strong parameter-style validation for Rails or plain Ruby apps"
  spec.description   = "Provides a DSL to validate and permit params like Rails strong parameters"
  spec.homepage      = "https://github.com/your_username/rails_validation"
  spec.license       = "MIT"
  spec.files         = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]
  spec.executables = ["rails_validation"]
  spec.bindir      = "exe"

  spec.add_dependency "activesupport", ">= 6.0"
  spec.add_dependency "rails_param", ">= 0.9", "< 1.4"
  spec.add_dependency "activemodel", ">= 6.0"

  spec.add_development_dependency "debug"
end
