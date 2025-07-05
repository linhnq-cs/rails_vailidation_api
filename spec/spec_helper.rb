require "rspec"
require "active_support/all"
require "rails_param"
require_relative "../lib/rails_validation_api"

module ActionController
  class Parameters < Hash
    def to_unsafe_h
      to_h
    end
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end