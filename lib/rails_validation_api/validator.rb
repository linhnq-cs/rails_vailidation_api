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
      self.params = (defined?(ActionController::Parameters) && params.is_a?(ActionController::Parameters)) ? params.to_unsafe_h : params
      @rules = rules
      @errors = []
    end

    def validate
      return false if @rules.nil? || @rules.empty?

      @rules.each do |rule, _|
        validate_field(rule)
      end
      if @errors.any?
        @errors.each do |error|
          raise RailsValidationApi::Error.new(error[:field], :unprocessable_entity, error[:message])
        end
      end
      nil
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
      elsif items && params[field].is_a?(Array)
        validate_nested_array_items(field, items, params[field])
      end
    end

    def validate_nested_items(parent_field, items, nested_params)
      return unless items.is_a?(Array)

      items.each do |item_rule|
        next unless item_rule.is_a?(Hash)

        # Check if this is a nested validation rule (not a regular field validation)
        if item_rule.keys.any? { |k| k.to_s.end_with?('_validate') }
          # Handle nested validation rules
          item_rule.each do |rule_name, rule_config|
            next unless rule_name.to_s.end_with?('_validate') && rule_config.is_a?(Hash)
            
            nested_field = rule_config[:field]
            nested_type = rule_config[:type]
            nested_opts = rule_config[:opts] || []
            nested_items = rule_config[:items]
            
            if nested_field && nested_type && nested_params[nested_field]
              # Create a temporary validator for the nested rule
              temp_validator = self.class.new(nested_params, {})
              
              # Validate the nested field
              nested_opts.each do |opt|
                next unless opt.is_a?(Hash)
                
                begin
                  temp_validator.param! nested_field, nested_type, **opt
                rescue RailsParam::InvalidParameterError => e
                  message = (e.message).include?(nested_type.to_s) ? e.message : opt[:message]
                  @errors << { field: "#{parent_field}.#{nested_field}", message: message }
                end
              end
              
              # Handle nested items if present
              if nested_items && nested_params[nested_field].is_a?(Array)
                validate_nested_array_items("#{parent_field}.#{nested_field}", nested_items, nested_params[nested_field])
              end
            end
          end
        else
          # Handle regular item validation
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

    def validate_nested_array_items(parent_field, items, array_params)
      return unless items.is_a?(Array) && array_params.is_a?(Array)

      array_params.each_with_index do |array_item, array_index|
        next unless array_item.is_a?(Hash)

        items.each do |item_rule|
          next unless item_rule.is_a?(Hash)

          item_field = item_rule[:field]
          item_type = item_rule[:type]
          item_opts = item_rule[:opts] || []

          next unless item_field && item_type

          # Create a temporary validator for nested validation
          temp_validator = self.class.new(array_item, {})
          item_opts.each do |opt|
            next unless opt.is_a?(Hash)

            begin
              # Handle nested array validation within hash items
              if item_type == Array && opt[:type]
                temp_validator.param! item_field, item_type do |nested_array_param, nested_index|
                  begin
                    nested_array_param.param! nested_index, opt[:type], **opt.except(:type)
                  rescue RailsParam::InvalidParameterError => e
                    message = (e.message).include?(item_type.to_s) ? e.message : opt[:message]
                    # message = opt[:message] || e.message || "Invalid value at index #{nested_index} for #{item_field}"
                    @errors << { field: "#{parent_field}[#{array_index}].#{item_field}[#{nested_index}]", message: message }
                  end
                end
              else
                temp_validator.param! item_field, item_type, **opt
              end
            rescue RailsParam::InvalidParameterError => e
              message = (e.message).include?(item_type.to_s) ? e.message : opt[:message]
              @errors << { field: "#{parent_field}[#{array_index}].#{item_field}", message: message }
            end
          end
        end
      end
    end
  end
end
