require "date"
require "time"
require "bigdecimal"
require "active_support/all"

module RailsValidationApi
  class Validator
    attr_accessor :params
    attr_reader :errors

    def initialize(params, rules)
      self.params = params.is_a?(ActionController::Parameters) ? params.to_unsafe_h : params
      @rules = rules
      @errors = []
    end

    def validate
      return false if @rules.nil? || @rules.empty?

      @rules.each do |rule, _|
        validate_field(rule)
      end
      if @errors.any?
        # Only raise the first error to match expected behavior
        first_error = @errors.first
        raise RailsValidationApi::Error.new(first_error[:field], :unprocessable_entity, first_error[:message])
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

      # Get the field value from params
      value = params[field]

      # Validate the main field
      opts.each do |opt|
        next unless opt.is_a?(Hash)

        # Check if field is required and missing
        if opt[:required] && (value.nil? || (value.is_a?(String) && value.empty?))
          message = opt[:message] || "Parameter #{field} is required"
          @errors << { field: field, message: message }
          next
        end

        # Skip further validation if field is not required and is nil/empty
        next if !opt[:required] && (value.nil? || (value.is_a?(String) && value.empty?))

        # Type validation
        unless value.nil? || valid_type?(value, type)
          message = opt[:message] || "Parameter #{field} must be of type #{type}"
          @errors << { field: field, message: message }
          next
        end

        # Additional validations
        validate_options(field, value, opt)
      end

      # Validate nested items if present (for Hash/Array fields)
      if items && value.is_a?(Hash)
        validate_nested_items(field, items, value)
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

        # Validate nested field
        value = nested_params[item_field]
        item_opts.each do |opt|
          next unless opt.is_a?(Hash)

          # Check if field is required and missing
          if opt[:required] && (value.nil? || (value.is_a?(String) && value.empty?))
            message = opt[:message] || "Parameter #{parent_field}.#{item_field} is required"
            @errors << { field: "#{parent_field}.#{item_field}", message: message }
            next
          end

          # Skip further validation if field is not required and is nil/empty
          next if !opt[:required] && (value.nil? || (value.is_a?(String) && value.empty?))

          # Type validation
          unless value.nil? || valid_type?(value, item_type)
            message = opt[:message] || "Parameter #{parent_field}.#{item_field} must be of type #{item_type}"
            @errors << { field: "#{parent_field}.#{item_field}", message: message }
            next
          end

          # Additional validations
          validate_options("#{parent_field}.#{item_field}", value, opt)
        end
      end
    end

    def valid_type?(value, type)
      case type
      when String
        value.is_a?(String)
      when Integer
        value.is_a?(Integer)
      when Float
        value.is_a?(Float) || value.is_a?(Integer)
      when Hash
        value.is_a?(Hash)
      when Array
        value.is_a?(Array)
      when TrueClass, FalseClass
        value.is_a?(TrueClass) || value.is_a?(FalseClass)
      else
        value.is_a?(type)
      end
    end

    def validate_options(field, value, opt)
      # Handle min validation
      if opt[:min] && value.respond_to?(:to_i) && value.to_i < opt[:min]
        message = opt[:message] || "Parameter #{field} must be at least #{opt[:min]}"
        @errors << { field: field, message: message }
      end

      # Handle max validation
      if opt[:max] && value.respond_to?(:to_i) && value.to_i > opt[:max]
        message = opt[:message] || "Parameter #{field} must be at most #{opt[:max]}"
        @errors << { field: field, message: message }
      end

      # Handle format validation
      if opt[:format] && value.is_a?(String) && !(value =~ opt[:format])
        message = opt[:message] || "Parameter #{field} format is invalid"
        @errors << { field: field, message: message }
      end

      # Handle blank validation
      if opt[:blank] == false && value.is_a?(String) && value.strip.empty?
        message = opt[:message] || "Parameter #{field} cannot be blank"
        @errors << { field: field, message: message }
      end
    end
  end
end
