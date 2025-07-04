# frozen_string_literal: true
module AutoLoadRailsValidationApi
  extend ActiveSupport::Concern

  included do
    before_action :set_validation_context
    before_action :auto_load_method
  end

  def auto_load_method
    call_validator
  end

  private

  def set_validation_context
    @params = params
    @controller = controller_name
    @action = action_name
    @model_name = controller_name.classify
    @account = Current.account rescue nil
  end

  def set_validator
    klass = Module.const_get(validator_name) rescue nil
    param_klass = Module.const_get(param_object_validator_name) rescue nil

    @validator = klass.new(@model_name, @account) if klass.present?
    @param_validator = param_klass.new if param_klass.present?
  end

  def validator_name
    "API::#{@model_name}Validator"
  end

  def param_object_validator_name
    "API::ValidateParameters::#{@model_name}Validator"
  end

  def call_validator(action: nil, opts: {})
    set_validator
    action = (action || action_name).to_sym
    opts = opts.blank? ? params : opts
    rules = @param_validator.send(action) rescue nil
    if rules.present?
      validator = RailsValidationApi::Validator.new(params, rules)
      validator.validate
    end
    get_params = @validator.method(action).arity rescue nil

    return get_params if get_params.nil?

    if get_params == 0
      begin
        @validator.send(action)
      rescue NoMethodError => ex
        nil
      rescue Exception => ex
        raise RailsValidationApi::Error.new(ex.status, ex.message)
      end
    else
      begin
        @validator.send(action, opts)
      rescue NoMethodError => ex
        nil
      rescue => ex
        status_code = ex.is_a?(ActiveRecord::RecordNotFound) ? :not_found : ex.status
        raise RailsValidationApi::Error.new(status_code, ex.message)
      end
    end
  end
end
