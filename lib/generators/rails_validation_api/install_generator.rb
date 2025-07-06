require "rails/generators"

module RailsValidationApi
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_initializer
        template "rails_validation_api.rb", "config/initializers/rails_validation_api.rb"
      end
    end
  end
end
