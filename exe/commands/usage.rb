puts <<~TEXT
  -------------------------------------------------------------------------------------------------------------------------------------------------
  |    Add "include AutoLoadRailsValidationApi" to your controller ex: API::BaseController < ApplicationController to use the RailsValidationApi  |
  |    Add "config.autoload_paths += %w(\#{config.root}/app/validators/)" in config/application.rb to autoload validators.                         |
  |-----------------------------------------------------------------------------------------------------------------------------------------------|                                                                                                                                       |     
  |    To use the RailsValidationApi, you need to add the following line to your Gemfile:                                                         |
  |    Usage: bundle exec rails_validation_api <command> [name]                                                                                   |
  |    Commands:                                                                                                                                  |
  |      install                  Install the rails_validation_api gem.                                                                           |
  |      generate <name>          Generate a parameter validator and a validator for the specified name.                                          |
  |      generate_parameter <name> Generate a parameter validator for the specified name.                                                         |
  |      destroy <name>           Destroy the validator and parameter validator for the specified name.                                           |
  |------------------------------------------------------------------------------------------------------------------------------------------------
  |    Example:                                                                                                                                   |
  |      bundle exec rails_validation_api generate purchaseorder                                                                                  |
  |------------------------------------------------------------------------------------------------------------------------------------------------
TEXT
