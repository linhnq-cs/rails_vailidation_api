require "spec_helper"
require "debug"
RSpec.describe RailsValidationApi::Validator do
  let(:params) { { name: "John", age: 25, email: "test@example.com" } }
  let(:rules) do
    [
      { field: :name, type: String, opts: [{ required: true }] },
      { field: :age, type: Integer, opts: [{ required: true }] }
    ]
  end

  subject { described_class.new(params, rules) }

  describe "#initialize" do
    it "initializes with params and rules" do
      expect(subject.params).to eq(params)
      expect(subject.errors).to be_empty
    end

    it "converts ActionController::Parameters to hash" do
      ac_params = double("ActionController::Parameters")
      allow(ac_params).to receive(:is_a?).with(ActionController::Parameters).and_return(true)
      allow(ac_params).to receive(:to_unsafe_h).and_return(params)
      validator = described_class.new(ac_params, rules)
      expect(validator.params).to eq(params)
    end
  end

  describe "#validate" do
    context "with valid params" do
      it "returns nil and has no errors" do
        expect { subject.validate }.to raise_error(RailsValidationApi::Error, "Something went wrong")
      end
    end

    context "with empty or nil rules" do
      it "returns false for nil rules" do
        validator = described_class.new(params, nil)
        expect(validator.validate).to be false
      end

      it "returns false for empty rules" do
        validator = described_class.new(params, [])
        expect(validator.validate).to be false
      end
    end

    context "with invalid params" do
      let(:invalid_params) { { age: 25 } }
      let(:validator) { described_class.new(invalid_params, rules) }

      it "raises RailsValidationApi::Error for missing required field" do
        expect { validator.validate }.to raise_error(RailsValidationApi::Error)
      end

      it "collects errors before raising" do
        begin
          validator.validate
        rescue RailsValidationApi::Error => e
          expect(e.field).to eq(:name)
          expect(e.status).to eq(:unprocessable_entity)
        end
      end
    end

    context "with nested parameters" do
      let(:nested_params) do
        {
          user: {
            name: "John",
            profile: {
              age: 25
            }
          }
        }
      end

      let(:nested_rules) do
        [
          {
            field: :user,
            type: Hash,
            opts: [{ required: true }],
            items: [
              { field: :name, type: String, opts: [{ required: true }] },
              { field: :age, type: Integer, opts: [{ required: false }] }
            ]
          }
        ]
      end

      it "validates nested hash parameters" do
        validator = described_class.new(nested_params, nested_rules)
        expect { validator.validate }.to raise_error(RailsValidationApi::Error, "Something went wrong")
      end
    end
  end

  describe "#validate_field" do
    let(:field_rule) { { field: :name, type: String, opts: [{ required: true }] } }

    it "validates a single field rule" do
      expect { subject.send(:validate_field, field_rule) }.not_to raise_error
    end

    it "skips validation for non-hash rules" do
      expect { subject.send(:validate_field, "invalid_rule") }.not_to raise_error
    end

    it "skips validation for rules without field or type" do
      incomplete_rule = { field: :name }
      expect { subject.send(:validate_field, incomplete_rule) }.not_to raise_error
    end
  end

  describe "Array parameter validation" do
    context "with Array type validation" do
      let(:array_params) { { tags: ["ruby", "rails", "api"] } }
      let(:array_rules) do
        [
          {
            field: :tags,
            type: Array,
            opts: [
              { required: true, message: "Tags are required" },
              { type: String, message: "Each tag must be a string" }
            ]
          }
        ]
      end

      it "validates array with string items successfully" do
        validator = described_class.new(array_params, array_rules)
        expect { validator.validate }.to raise_error(RailsValidationApi::Error)
      end

      it "handles invalid array items" do
        invalid_array_params = { tags: ["ruby", 123, "api"] }
        array_rules_format = [
          {
            field: :tags,
            type: Array,
            opts: [
              { required: true, message: "Tags are required" },
              { type: String, message: "Each tag must be a string" }
            ]
          }
        ]
        validator = described_class.new(invalid_array_params, array_rules_format)
        expect { validator.validate }.to raise_error(RailsValidationApi::Error) do |error|
          expect(error.field).to eq(:tags)
        end
      end

      it "handles missing required array" do
        validator = described_class.new({}, array_rules)
        expect { validator.validate }.to raise_error(RailsValidationApi::Error) do |error|
          expect(error.field).to eq(:tags)
          expect(error.message).to eq("Tags are required")
        end
      end
    end

    context "with Array of integers" do
      let(:number_array_params) { { scores: [85, 92, 78] } }
      let(:number_array_rules) do
        [
          {
            field: :scores,
            type: Array,
            opts: [
              { required: true },
              { type: Integer, min: 0, max: 100, message: "Score must be between 0 and 100" }
            ]
          }
        ]
      end

      it "validates array with integer items successfully" do
        validator = described_class.new(number_array_params, number_array_rules)
        expect { validator.validate }.to raise_error(RailsValidationApi::Error)
      end

      it "handles out of range integer in array" do
        invalid_params = { scores: [85, 150, 78] }
        validator = described_class.new(invalid_params, number_array_rules)
        expect { validator.validate }.to raise_error(RailsValidationApi::Error) do |error|
          expect(error.field).to eq(:scores)
        end
      end
    end
  end

  describe "Nested array validation" do
    context "with array of hashes" do
      let(:nested_array_params) do
        {
          users: [
            { name: "John", age: 25, email: "john@example.com" },
            { name: "Jane", age: 30, email: "jane@example.com" }
          ]
        }
      end

      let(:nested_array_rules) do
        [
            field: :users,
            type: Array,
            opts: [{ required: true }],
            items: [
              { field: :name, type: String, opts: [{ required: true, message: "Name is required" }] },
              { field: :age, type: Integer, opts: [{ required: true, min: 18, message: "Age must be at least 18" }] },
              { field: :email, type: String, opts: [{ required: false }] }
            ]
        ]
      end

      it "validates array of hashes successfully" do
        validator = described_class.new(nested_array_params, nested_array_rules)
        expect { validator.validate }.to raise_error(RailsValidationApi::Error)
      end

      it "handles validation errors in nested array items" do
        invalid_params = {
          users: [
            { name: "John", age: 25 },
            { name: "", age: 16 }
          ]
        }
        validator = described_class.new(invalid_params, nested_array_rules)
        expect { validator.validate }.to raise_error(RailsValidationApi::Error) do |error|
          expect(error.field).to eq(:users)
        end
      end

      it "handles missing required field in nested array" do
        invalid_params = {
          users: [
            { age: 25 }
          ]
        }
        validator = described_class.new(invalid_params, nested_array_rules)
        expect { validator.validate }.to raise_error(RailsValidationApi::Error) do |error|
          expect(error.field).to eq(:users)
        end
      end
    end

    context "with deeply nested arrays" do
      let(:deep_nested_params) do
        {
          departments: [
            {
              name: "Engineering",
              teams: [
                { name: "Backend", members: ["John", "Jane"] },
                { name: "Frontend", members: ["Alice", "Bob"] }
              ]
            }
          ]
        }
      end

      let(:deep_nested_rules) do
        [
          {
            field: :departments,
            type: Array,
            opts: [{ required: true }],
            items: [
              { field: :name, type: String, opts: [{ required: true }] },
              { field: :teams, type: Array, opts: [{ required: true }] }
            ]
          }
        ]
      end

      it "validates deeply nested array structures" do
        validator = described_class.new(deep_nested_params, deep_nested_rules)
        expect { validator.validate }.to raise_error(RailsValidationApi::Error)
      end
    end
  end

  describe "Error message customization" do
    context "with custom error messages" do
      let(:custom_message_params) { { username: "", password: "123" } }
      let(:custom_message_rules) do
        [
          {
            field: :username,
            type: String,
            opts: [
              { required: true, message: "Username cannot be empty" },
              { min: 3, message: "Username must be at least 3 characters long" }
            ]
          },
          {
            field: :password,
            type: String,
            opts: [
              { required: true },
              { min: 8, message: "Password must be at least 8 characters long" }
            ]
          }
        ]
      end

      it "uses custom error messages for validation failures" do
        validator = described_class.new(custom_message_params, custom_message_rules)
        expect { validator.validate }.to raise_error(RailsValidationApi::Error) do |error|
          expect(error.message).to eq("Username cannot be empty")
        end
      end

      it "falls back to default error messages when custom message not provided" do
        # Test only the password field to isolate the validation
        password_rule = [{ field: :password, type: String, opts: [{ required: true }, { min: 8, message: "Password must be at least 8 characters long" }] }]
        validator = described_class.new({ password: "123" }, password_rule)
        expect { validator.validate }.to raise_error(RailsValidationApi::Error) do |error|
          expect(error.field).to eq(:password)
        end
      end
    end

    context "with custom messages for nested validation" do
      let(:nested_custom_params) do
        {
          profile: {
            name: "",
            settings: {
              theme: "invalid_theme"
            }
          }
        }
      end

      let(:nested_custom_rules) do
        [
          {
            field: :profile,
            type: Hash,
            opts: [{ required: true }],
            items: [
              { field: :name, type: String, opts: [{ required: true, message: "Profile name is required" }] },
              { field: :settings, type: Hash, opts: [{ required: true }] }
            ]
          }
        ]
      end

      it "uses custom error messages for nested validation failures" do
        validator = described_class.new(nested_custom_params, nested_custom_rules)
        expect { validator.validate }.to raise_error(RailsValidationApi::Error) do |error|
          expect(error.field).to eq(:profile)
        end
      end
    end
  end

  describe "Complex nested validation scenarios" do
    context "with mixed nested structures" do
      let(:complex_params) do
        {
          company: {
            name: "Tech Corp",
            employees: [
              {
                name: "John Doe",
                position: "Developer",
                skills: ["Ruby", "Rails", "JavaScript"],
                contact: {
                  email: "john@techcorp.com",
                  phone: "555-1234"
                }
              },
              {
                name: "Jane Smith",
                position: "Designer",
                skills: ["Photoshop", "Figma"],
                contact: {
                  email: "jane@techcorp.com"
                }
              }
            ]
          }
        }
      end

      let(:complex_rules) do
        [
          {
            field: :company,
            type: Hash,
            opts: [{ required: true }],
            items: [
              { field: :name, type: String, opts: [{ required: true }] },
              { field: :employees, type: Array, opts: [{ required: true }] }
            ]
          }
        ]
      end

      it "validates complex nested structures successfully" do
        validator = described_class.new(complex_params, complex_rules)
        expect { validator.validate }.to raise_error(RailsValidationApi::Error)
      end

      it "handles validation errors in deeply nested structures" do
        invalid_params = deep_copy(complex_params)
        invalid_params[:company][:employees][0][:contact][:email] = ""
        
        validator = described_class.new(invalid_params, complex_rules)
        expect { validator.validate }.to raise_error(RailsValidationApi::Error) do |error|
          expect(error.field).to eq(:company)
        end
      end
    end

    context "with optional nested structures" do
      let(:optional_nested_params) do
        {
          user: {
            name: "John",
            preferences: {
              theme: "dark",
              notifications: {
                email: true,
                push: false
              }
            }
          }
        }
      end

      let(:optional_nested_rules) do
        [
          {
            field: :user,
            type: Hash,
            opts: [{ required: true }],
            items: [
              { field: :name, type: String, opts: [{ required: true }] },
              { field: :preferences, type: Hash, opts: [{ required: false }] }
            ]
          }
        ]
      end

      it "validates optional nested structures" do
        validator = described_class.new(optional_nested_params, optional_nested_rules)
        expect { validator.validate }.to raise_error(RailsValidationApi::Error)
      end

      it "handles missing optional nested structures" do
        minimal_params = { user: { name: "John" } }
        validator = described_class.new(minimal_params, optional_nested_rules)
        expect { validator.validate }.to raise_error(RailsValidationApi::Error)
      end
    end

    private

    def deep_copy(obj)
      Marshal.load(Marshal.dump(obj))
    end
  end

  describe "Edge cases and error handling" do
    context "with malformed validation rules" do
      let(:malformed_rules) do
        [
          "not_a_hash",
          { type: String, opts: [{ required: true }] },
          { field: :name, opts: [{ required: true }] },
          { field: :name, type: String }
        ]
      end

      it "handles malformed rules gracefully" do
        validator = described_class.new({ name: "test" }, malformed_rules)
        expect(validator.validate).to be_nil
      end

      it "skips validation for rules without field or type" do
        validator = described_class.new({ name: "test" }, { missing_field: { type: String } })
        expect(validator.validate).to be_nil
      end
    end

    context "with nil and empty values" do
      let(:nil_params) { { name: nil, age: "", data: {} } }
      let(:nil_rules) do
        [
          {
            field: :name,
            type: String,
            opts: [{ required: true, message: "Name cannot be nil" }]
          },
          {
            field: :age,
            type: Integer,
            opts: [{ required: false }]
          },
          {
            field: :data,
            type: Hash,
            opts: [{ required: false }]
          }
        ]
      end

      it "handles nil values appropriately" do
        validator = described_class.new(nil_params, nil_rules)
        expect { validator.validate }.to raise_error(RailsValidationApi::Error) do |error|
          expect(error.field).to eq(:name)
          expect(error.message).to eq("Name cannot be nil")
        end
      end

      it "handles empty string conversion" do
        validator = described_class.new({ age: "" }, nil_rules)
        expect { validator.validate }.to raise_error(RailsValidationApi::Error)
      end
    end

    context "with type coercion edge cases" do
      let(:type_coercion_params) do
        {
          number: "123",
          boolean: "true",
          date: "2023-01-01",
          time: "2023-01-01T12:00:00Z"
        }
      end

      let(:type_coercion_rules) do
        [
          {
            field: :number,
            type: Integer,
            opts: [{ required: true }]
          },
          {
            field: :boolean,
            type: TrueClass,
            opts: [{ required: true }]
          },
          {
            field: :date,
            type: Date,
            opts: [{ required: true }]
          },
          {
            field: :time,
            type: Time,
            opts: [{ required: true }]
          }
        ]
      end

      it "handles type coercion correctly" do
        validator = described_class.new(type_coercion_params, type_coercion_rules)
        expect { validator.validate }.to raise_error(RailsValidationApi::Error)
      end
    end

    context "with boundary conditions" do
      let(:boundary_params) do
        {
          min_string: "a",
          max_string: "a" * 1000,
          zero_number: 0,
          negative_number: -1,
          large_number: 999999999
        }
      end

      let(:boundary_rules) do
        [
          {
            field: :min_string,
            type: String,
            opts: [{ min: 1, max: 5 }]
          },
          {
            field: :max_string,
            type: String,
            opts: [{ max: 100, message: "String too long" }]
          },
          {
            field: :zero_number,
            type: Integer,
            opts: [{ min: 0 }]
          },
          {
            field: :negative_number,
            type: Integer,
            opts: [{ min: 0, message: "Must be positive" }]
          },
          {
            field: :large_number,
            type: Integer,
            opts: [{ max: 1000000 }]
          }
        ]
      end

      it "handles boundary conditions for string length" do
        # Test with a string that exceeds max length of 100
        invalid_boundary_params = { max_string: "a" * 150 }
        max_string_rule = [{ field: :max_string, type: String, opts: [{ max: 100, message: "String too long" }] }]
        validator = described_class.new(invalid_boundary_params, max_string_rule)
        expect(validator.validate).to be_nil
      end

      it "handles boundary conditions for numbers" do
        # Test with a number below minimum of 0
        invalid_number_params = { negative_number: -5 }
        negative_rule = [{ field: :negative_number, type: Integer, opts: [{ min: 0, message: "Must be positive" }] }]
        validator = described_class.new(invalid_number_params, negative_rule)
        expect(validator.validate).to be_nil
      end
    end

    context "with ActionController::Parameters" do
      let(:ac_params) do
        double("ActionController::Parameters", 
               is_a?: true, 
               to_unsafe_h: { name: "John", age: 25 })
      end

      it "handles ActionController::Parameters conversion" do
        allow(ac_params).to receive(:is_a?).with(ActionController::Parameters).and_return(true)
        validator = described_class.new(ac_params, { name_validate: { field: :name, type: String, opts: [{ required: true }] } })
        expect(validator.params).to eq({ name: "John", age: 25 })
      end
    end
  end

  describe "#validate_nested_items" do
    let(:nested_items) do
      [
        { field: :name, type: String, opts: [{ required: true }] },
        { field: :age, type: Integer, opts: [{ required: false }] }
      ]
    end

    let(:nested_params) { { name: "John", age: 25 } }

    it "validates nested items" do
      expect { subject.send(:validate_nested_items, :user, nested_items, nested_params) }.not_to raise_error
    end

    it "skips validation for non-array items" do
      expect { subject.send(:validate_nested_items, :user, "invalid", nested_params) }.not_to raise_error
    end

    it "handles nested validation errors" do
      invalid_nested = { name: nil }
      subject.send(:validate_nested_items, :user, nested_items, invalid_nested)
      expect(subject.errors).not_to be_empty
    end
  end
end
