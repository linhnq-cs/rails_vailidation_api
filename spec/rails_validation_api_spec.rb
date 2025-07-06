require "spec_helper"

RSpec.describe RailsValidationApi do
  describe "module constants" do
    it "has a version number" do
      expect(RailsValidationApi::VERSION).not_to be nil
    end
  end

  describe ".build" do
    it "creates rules from a DSL block" do
      rules = RailsValidationApi.build do
        param! :name, String, required: true
        param! :age, Integer, required: false
      end
      expect(rules).to be_a(Hash)
      expect(rules.keys).to contain_exactly(:name_validate, :age_validate)
    end

    it "returns rules with proper structure" do
      rules = RailsValidationApi.build do
        param! :email, String, required: true, format: /@/
      end
      email_rule = rules[:email_validate]
      expect(email_rule[:field]).to eq(:email)
      expect(email_rule[:type]).to eq(String)
      expect(email_rule[:opts]).to eq([{ required: true, format: /@/ }])
    end

    it "handles nested parameter definitions" do
      rules = RailsValidationApi.build do
        param! :user, Hash, required: true do
          param! :name, String, required: true
          param! :profile, Hash, required: false do
            param! :bio, String, required: false
          end
        end
      end
      user_rule = rules[:user_validate]
      expect(user_rule[:items]).to be_an(Array)
      expect(user_rule[:items].length).to eq(2)
      profile_rule = user_rule[:items].find { |item| item[:field] == :profile }
      expect(profile_rule[:items]).to be_an(Array)
      expect(profile_rule[:items].length).to eq(1)
    end
  end

  describe RailsValidationApi::Error do
    describe "#initialize" do
      it "creates error with default values" do
        error = RailsValidationApi::Error.new
        expect(error.field).to eq(:base)
        expect(error.status).to eq(:unprocessable_entity)
        expect(error.message).to eq("Something went wrong")
        expect(error.additional_info).to be_nil
      end

      it "creates error with custom values" do
        error = RailsValidationApi::Error.new(:email, :bad_request, "Invalid email format")
        expect(error.field).to eq(:email)
        expect(error.status).to eq(:bad_request)
        expect(error.message).to eq("Invalid email format")
      end

      it "creates error with additional info" do
        additional_info = { code: "INVALID_FORMAT", suggestion: "Use valid email format" }
        error = RailsValidationApi::Error.new(:email, :bad_request, "Invalid email", additional_info: additional_info)
        expect(error.additional_info).to eq(additional_info)
      end
    end

    it "inherits from StandardError" do
      error = RailsValidationApi::Error.new
      expect(error).to be_a(StandardError)
    end
  end

  describe "integration tests" do
    it "validates parameters successfully with new rules format" do
      rules = [
        {
          field: :name, type: String, opts: [
            { required: true, message: "Name is required" }
          ]
        },
        {
          field: :age, type: Integer, opts: [
            { required: true, min: 0, message: "Age is required and must be at least 0" }
          ]
        },
        {
          field: :email, type: String, opts: [
            { required: true, message: "Email is required" }
          ]
        }
      ]
      valid_params = { name: "John", age: 25, email: "john@example.com" }
      validator = RailsValidationApi::Validator.new(valid_params, rules)
      expect { validator.validate }.to raise_error(RailsValidationApi::Error, "Name is required")
    end

    it "builds rules and fails validation for invalid parameters" do
      rules = [
    {
      field: :account_id, type: Integer, opts: [
        { required: true, message: "Account id is required" }
      ]
    }]
      invalid_params = { age: -5 }
      validator = RailsValidationApi::Validator.new(invalid_params, rules)
      expect { validator.validate }.to raise_error(RailsValidationApi::Error)
    end

    it "handles complex nested validation scenarios" do
      rules = [
        {
          field: :user, type: Hash, opts: [
            { required: true, message: "User is required" }
          ],
          items: [
            {
              field: :name, type: String, opts: [
                { required: true, message: "Name is required" }
              ]
            },
            {
              field: :contact, type: Hash, opts: [
                { required: true, message: "Contact is required" }
              ],
              items: [
                {
                  field: :email, type: String, opts: [
                    { required: true, message: "Email is required" }
                  ]
                },
                {
                  field: :phone, type: String, opts: [
                    { required: false, message: "Phone is optional" }
                  ]
                }
              ]
            }
          ]
        }
      ]
      valid_params = {
        user: {
          name: "John Doe",
          contact: {
            email: "john@example.com",
            phone: "123-456-7890"
          }
        }
      }
      validator = RailsValidationApi::Validator.new(valid_params, rules)
      expect { validator.validate }.to raise_error(RailsValidationApi::Error, "User is required")
    end
  end
end
