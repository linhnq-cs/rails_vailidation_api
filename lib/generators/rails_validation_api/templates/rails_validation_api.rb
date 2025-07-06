require "auto_load_rails_validation_api"

Rails.application.config.autoload_paths += %W(#{Rails.root}/app/validators)

ActiveSupport.on_load(:action_controller) do
  include AutoLoadRailsValidationApi
end
