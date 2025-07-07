module GenerateValidator
  def generate_parameter_validator(name)
    name = name.classify
    api = check_inflection(name)
    class_name = "#{name.camelize}Validator"
    path = "app/validators/api/validate_parameters/#{name.downcase}_validator.rb"

    FileUtils.mkdir_p(File.dirname(path))

    if File.exist?(path)
      puts "⚠️  Validator already exists at #{path}"
    else
      File.write(path, <<~RUBY)
        # frozen_string_literal: true

        class #{api}::ValidateParameters::#{class_name}
          FIELDS_VALIDATES = {
          #  account_id_validate:
          #  {
          #    field: :account_id, type: Integer, opts: [
          #      { required: true, message: "Account id is required" }
          #    ]
          #  }
          }.freeze

          def index
            [
               # FIELDS_VALIDATES[:account_id_validate]
            ]
          end
        end
      RUBY

      puts "✅ Created #{path}"
    end
  end

  def destroy_validator(name)
    name = name.classify
    params_path = "app/validators/api/validate_parameters/#{name.downcase}_validator.rb"
    path = "app/validators/api/#{name.downcase}_validator.rb"

    if File.exist?(path)
      File.delete(path)
      puts "🗑️  Deleted #{path}"
    else
      puts "⚠️  File not found: #{path}"
    end
    if File.exist?(params_path)
      File.delete(params_path)
      puts "🗑️  Deleted #{params_path}"
    else
      puts "⚠️  File not found: #{params_path}"
    end
  end

  def generate_validator(name)
    name = name.classify
    api = check_inflection(name)
    class_name = "#{name.camelize}Validator"
    path = "app/validators/api/#{name.downcase}_validator.rb"

    FileUtils.mkdir_p(File.dirname(path))

    if File.exist?(path)
      puts "⚠️  Validator already exists at #{path}"
    else
      File.write(path, <<~RUBY)
        # frozen_string_literal: true

        class #{api}::#{class_name}
          def initialize(model_name, account)
            @model_name = model_name
            @account = account
          end

          def index(opts)
          end
        end
      RUBY

      puts "✅ Created #{path}"
    end
  end

  def usage
    require_relative "./usage"
  end
end
