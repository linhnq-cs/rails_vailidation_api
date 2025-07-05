# frozen_string_literal: true

require "logger"
require "active_model"
require "active_support"
require "active_support/core_ext/hash"
require "date"
require "time"
require "bigdecimal"
require "rails_param"
require_relative "rails_validation_api/dsl"
require_relative "rails_validation_api/validator"
require "active_support/concern"
require "active_support/core_ext/string/inflections"

module RailsValidationApi
  class Error < StandardError
    attr_reader :field, :status, :additional_info
    def initialize(field = :base, status = :unprocessable_entity, message = nil, additional_info: nil)
      @field   = field
      @status  = status
      @additional_info = additional_info
      super(message || "Something went wrong")
    end
  end

  def self.build(&block)
    dsl = DSL.new
    dsl.instance_eval(&block)
    dsl.rules
  end
end
