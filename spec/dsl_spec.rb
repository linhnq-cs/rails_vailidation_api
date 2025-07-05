require "spec_helper"

RSpec.describe RailsValidationApi::DSL do
  subject { described_class.new }

  describe "#initialize" do
    it "initializes with empty rules hash" do
      expect(subject.rules).to eq({})
    end
  end

  describe "#param!" do
    it "adds a basic parameter rule" do
      subject.param! :name, String, required: true

      expect(subject.rules).to have_key(:name_validate)
      rule = subject.rules[:name_validate]
      expect(rule[:field]).to eq(:name)
      expect(rule[:type]).to eq(String)
      expect(rule[:opts]).to eq([{ required: true }])
    end

    it "adds a parameter rule with multiple options" do
      subject.param! :age, Integer, required: true, min: 0, max: 120

      rule = subject.rules[:age_validate]
      expect(rule[:field]).to eq(:age)
      expect(rule[:type]).to eq(Integer)
      expect(rule[:opts]).to eq([{ required: true, min: 0, max: 120 }])
    end

    it "adds a parameter rule without options" do
      subject.param! :email, String
      
      rule = subject.rules[:email_validate]
      expect(rule[:field]).to eq(:email)
      expect(rule[:type]).to eq(String)
      expect(rule[:opts]).to eq([{}])
    end

    it "handles nested parameter validation with block" do
      subject.param! :user, Hash, required: true do
        param! :name, String, required: true
        param! :age, Integer, required: false
      end

      rule = subject.rules[:user_validate]
      expect(rule[:field]).to eq(:user)
      expect(rule[:type]).to eq(Hash)
      expect(rule[:opts]).to eq([{ required: true }])
      expect(rule[:items]).to be_an(Array)
      expect(rule[:items].length).to eq(2)

      name_rule = rule[:items].find { |item| item[:field] == :name }
      age_rule = rule[:items].find { |item| item[:field] == :age }

      expect(name_rule[:type]).to eq(String)
      expect(name_rule[:opts]).to eq([{ required: true }])
      expect(age_rule[:type]).to eq(Integer)
      expect(age_rule[:opts]).to eq([{ required: false }])
    end

    it "handles deeply nested parameter validation" do
      subject.param! :user, Hash, required: true do
        param! :profile, Hash, required: true do
          param! :name, String, required: true
          param! :bio, String, required: false
        end
      end

      rule = subject.rules[:user_validate]
      expect(rule[:items]).to be_an(Array)
      expect(rule[:items].length).to eq(1)

      profile_rule = rule[:items].first
      expect(profile_rule[:field]).to eq(:profile)
      expect(profile_rule[:items]).to be_an(Array)
      expect(profile_rule[:items].length).to eq(2)
    end

    it "generates correct rule keys" do
      subject.param! :user_name, String, required: true
      subject.param! :user_email, String, required: true

      expect(subject.rules).to have_key(:user_name_validate)
      expect(subject.rules).to have_key(:user_email_validate)
    end
  end

  describe "#rules" do
    it "returns the rules hash" do
      subject.param! :name, String, required: true
      subject.param! :age, Integer, required: false

      rules = subject.rules
      expect(rules).to be_a(Hash)
      expect(rules.keys).to contain_exactly(:name_validate, :age_validate)
    end
  end

  describe "integration with block syntax" do
    it "works with instance_eval" do
      dsl = described_class.new

      dsl.instance_eval do
        param! :name, String, required: true
        param! :email, String, required: true, format: /@/
      end

      expect(dsl.rules.keys).to contain_exactly(:name_validate, :email_validate)

      name_rule = dsl.rules[:name_validate]
      email_rule = dsl.rules[:email_validate]

      expect(name_rule[:opts]).to eq([{ required: true }])
      expect(email_rule[:opts]).to eq([{ required: true, format: /@/ }])
    end
  end
end
