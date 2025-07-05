require "spec_helper"

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
        expect { subject.validate }.not_to raise_error
        expect(subject.errors).to be_empty
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
        expect { validator.validate }.not_to raise_error
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
