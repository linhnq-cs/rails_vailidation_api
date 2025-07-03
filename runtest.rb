require_relative "lib/rails_validation"
require_relative "lib/auto_load_rails_validation"

include AutoLoadRailsValidation

input = {
  account_id: 123,
  published_account_ids: ["acc1", "acc2"],
  search_criteria: "",
  approved_purchasing_list: {
    name: "",
    effective_date: "2024-12-01",
    list_type: "wrong_type"
  }
}
FIELDS_VALIDATES = {
  account_id_validate:
  {
    field: :account_id, type: Integer, opts: [
      { required: true, message: "Account id is required" }
    ]
  },
  search_criteria_validate:
  {
    field: :search_criteria, type: String, opts: [
      { required: true, message: "Search criteria is required" },
      { blank: false, message: "Search criteria cannot be blank" }
    ]
  }
}

controller = 'purchase_order_controller'
action = 'index'

validator = RailsValidation::Validator.new(input, FIELDS_VALIDATES)
puts "Valid? #{validator.validate}"
puts validator.errors.inspect
