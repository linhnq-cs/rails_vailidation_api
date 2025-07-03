# frozen_string_literal: true

require 'logger'
require 'active_model'
require 'active_support'
require 'rails_param'
require 'active_support/core_ext/hash'
require 'date'
require_relative 'rails_validation/dsl'
require_relative 'rails_validation/validator'
require "active_support/concern"
require "active_support/core_ext/string/inflections"
require 'rails_param'

module RailsValidation
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
