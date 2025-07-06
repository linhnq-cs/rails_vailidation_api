require "date"
require "time"
require "bigdecimal"
require "active_support/all"
require "rails_param"

module RailsValidationApi
  class Validator
    include RailsParam

    attr_accessor :params
    attr_reader :errors

    def initialize(params, rules)
      self.params = params.is_a?(ActionController::Parameters) ? params.to_unsafe_h : params
      @rules = rules
      @errors = []
    end

    def validate
      return false if @rules.nil? || @rules.empty?

      @rules.each do |rule_name, rule|
        validate_field(rule_name)
      end
      if @errors.any?
        @errors.each do |error|
          raise RailsValidationApi::Error.new(error[:field], :unprocessable_entity, error[:message])
        end
      end
    end

    private

    def validate_field(rule)
      return unless rule.is_a?(Hash)

      field = rule[:field]
      type  = rule[:type]
      opts  = rule[:opts] || []
      items = rule[:items]

      return unless field && type

      # Validate the main field
      opts.each do |opt|
        next unless opt.is_a?(Hash)

        begin
          if type == Array && opt[:type] # => Nested item type inside Array
            param! field, Array do |array_param, index|
              begin
                array_param.param! index, opt[:type], **opt.except(:type)
              rescue RailsParam::InvalidParameterError => e
                message = opt[:message] || e.message ||  "Invalid value at index #{index} for #{field}"
                @errors << { field: "#{field}[#{index}]", message: message }
              end
            end
          else
            param! field, type, **opt
          end
        rescue RailsParam::InvalidParameterError => e
          message = (e.message).include?(type.to_s) ? e.message : opt[:message]
          @errors << { field: field, message: message }
        end
      end

      # Validate nested items if present (for Hash/Array fields)
      if items && params[field].is_a?(Hash)
        validate_nested_items(field, items, params[field])
      end
    end

    def validate_nested_items(parent_field, items, nested_params)
      return unless items.is_a?(Array)

      items.each do |item_rule|
        next unless item_rule.is_a?(Hash)

        item_field = item_rule[:field]
        item_type = item_rule[:type]
        item_opts = item_rule[:opts] || []

        next unless item_field && item_type

        # Create a temporary validator for nested validation
        temp_validator = self.class.new(nested_params, {})
        item_opts.each do |opt|
          next unless opt.is_a?(Hash)

          begin
            temp_validator.param! item_field, item_type, **opt
          rescue RailsParam::InvalidParameterError => e
            message = (e.message).include?(item_type.to_s) ? e.message : opt[:message]
            @errors << { field: "#{parent_field}.#{item_field}", message: message }
          end
        end
      end
    end
  end
end
