# frozen_string_literal: true

module RailsValidation
  class DSL
    attr_reader :rules

    def initialize
      @rules = {}
    end

    def param!(name, type, **opts, &block)
      key = :"#{name}_validate"
      rule = { field: name, type: type, opts: [opts].compact }

      if block_given?
        nested = DSL.new
        nested.instance_eval(&block)
        rule[:items] = nested.rules.values
      end

      @rules[key] = rule
    end

    # def rules
      # @rules
    # end
  end
end
