# frozen_string_literal: true
module AutoLoadRailsValidationApi
  extend ActiveSupport::Concern

  included do
    before_action :set_validation_context
    before_action :auto_load_method
    rescue_from RailsValidationApi::Error, with: :render_validation_error
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
    "#{@name}::#{@model_name}Validator"
  end

  def param_object_validator_name
    "#{@name}::ValidateParameters::#{@model_name}Validator"
  end

  def call_validator(action: nil, opts: {})
    check_inflection
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

  def check_inflection
    app_root = defined?(Rails) ? Rails.root : Dir.pwd
    inflection_path = File.join(app_root, "config", "initializers", "inflections.rb")

    require inflection_path if File.exist?(inflection_path)
    @name ||= if ActiveSupport::Inflector.inflections.acronyms.key?("api")
      "API"
    else
      "Api"
    end
  end

  def render_validation_error(exception)
    render json: {
      errors: {
        field: exception.field,
        message: exception.message,
        additional_info: exception.additional_info
      }
    }, status: exception.status
    end
end
