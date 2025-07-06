# Rails Validation API

Enhanced parameter validation system for Rails APIs with automatic controller integration.

Rails Validation API provides a powerful for validating request parameters in Rails applications. Features include automatic validator loading based on controller/action names, nested parameter validation, custom error handling, and seamless integration with Rails controllers through concerns. Perfect for API applications requiring robust parameter validation with minimal boilerplate code.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails_validation_api'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install rails_validation_api
```

## Usage

### Initial Setup

After installing the gem, run the install command to set up the necessary files:

This will generate the required application validator structure in your Rails application.

```bash
bundle exec rails generate rails_validation_api:install                                                                           |
```

### Basic Usage

The gem provides automatic parameter validation through Rails controller concerns. It automatically loads validators based on controller and action names.

#### Example Controller

```ruby
class API::UsersController < ApplicationController
  def create
    # Parameters are automatically validated using API::ValidateParameters::UsersValidator
    # and API::UsersValidator (if they exist)
    
    # Your controller logic here
    render json: { message: "User created successfully" }
  end
end
```

#### Example Validator

```ruby
# app/validators/api/validate_parameters/users_validator.rb
class API::ValidateParameters::UsersValidator
  # Default empty hash - define your validation rules here
  FIELDS_VALIDATES = {}.freeze

  # Or with comprehensive validation rules defined:
  # FIELDS_VALIDATES = {
  #   # Basic field validation with opts array
  #   name_validate: {
  #     field: :name, 
  #     type: String, 
  #     opts: [
  #       { required: true, message: "Name is required" },
  #       { min: 2, message: "Name must be at least 2 characters" },
  #       { max: 50, message: "Name cannot exceed 50 characters" }
  #     ]
  #   },
  #   
  #   # Email validation with format and required
  #   email_validate: {
  #     field: :email, 
  #     type: String, 
  #     opts: [
  #       { required: true, message: "Email is required" },
  #       { format: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i, message: "Invalid email format" }
  #     ]
  #   },
  #   
  #   # Integer validation with range
  #   age_validate: {
  #     field: :age, 
  #     type: Integer, 
  #     opts: [
  #       { required: false },
  #       { min: 18, message: "Age must be at least 18" },
  #       { max: 120, message: "Age cannot exceed 120" }
  #     ]
  #   },
  #   
  #   # String validation with blank check
  #   search_criteria_validate: {
  #     field: :search_criteria, 
  #     type: String, 
  #     opts: [
  #       { required: true, message: "Search criteria is required" },
  #       { blank: false, message: "Search criteria cannot be blank" }
  #     ]
  #   },
  #   
  #   # Float validation with minimum value
  #   price_validate: {
  #     field: :price, 
  #     type: Float, 
  #     opts: [
  #       { required: true, message: "Price is required" },
  #       { min: 0.01, message: "Price must be greater than 0" }
  #     ]
  #   },
  #   
  #   # Boolean validation
  #   active_validate: {
  #     field: :active, 
  #     type: Boolean, 
  #     opts: [
  #       { required: false }
  #     ]
  #   },
  #   
  #   # Date validation
  #   birth_date_validate: {
  #     field: :birth_date, 
  #     type: Date, 
  #     opts: [
  #       { required: false }
  #     ]
  #   },
  #   
  #   # DateTime validation
  #   created_at_validate: {
  #     field: :created_at, 
  #     type: DateTime, 
  #     opts: [
  #       { required: false }
  #     ]
  #   },
  #   
  #   # Enum validation with 'in' option
  #   status_validate: {
  #     field: :status, 
  #     type: String, 
  #     opts: [
  #       { required: true, message: "Status is required" },
  #       { in: %w[active inactive pending], message: "Status must be active, inactive, or pending" }
  #     ]
  #   },
  #   
  #   # Array validation
  #   tags_validate: {
  #     field: :tags, 
  #     type: Array, 
  #     opts: [
  #       { required: false }
  #     ]
  #   }
  # }.freeze

  def create
    # Return validation rules for create action
    # FIELDS_VALIDATES.slice(:name, :email, :age, :status, :tags)
    []
  end

  def update
    # Return validation rules for update action (excluding some required fields)
    # FIELDS_VALIDATES.slice(:name, :email, :age, :active, :metadata)
    []
  end

  def index
    # Return validation rules for index action (typically query parameters)
    # FIELDS_VALIDATES.slice(:status, :tags, :created_at)
    []
  end
end
```

## Commands

### Generate Validators

Generate both parameter and business logic validators for a given name:

```bash
bundle exec rails_validation_api generate users
```

This creates:
- `app/validators/api/validate_parameters/users_validator.rb` - Parameter validation
- `app/validators/api/users_validator.rb` - Business logic validation

### Destroy Validators

Remove validators for a given name:

```bash
bundle exec rails_validation_api destroy users
```

This removes both parameter and business logic validators.

## Validation Options

### FIELDS_VALIDATES Structure

Each validation rule follows this structure:
```ruby
field_name_validate: {
  field: :field_name,    # The parameter field to validate
  type: Type,            # The expected data type
  opts: [                # Array of validation options
    { option: value, message: "custom message" }
  ],
  items: [               # Optional: Array of nested field validations (for Hash types)
    { field: :nested_field, type: Type, opts: [...] }
  ]
}
```

### Basic Types
- `String` - String validation with optional min/max length
- `Integer` - Integer validation with optional min/max range
- `Float` - Float validation with optional min/max range
- `Boolean` - Boolean validation (true/false)
- `Date` - Date validation
- `DateTime` - DateTime validation
- `Array` - Array validation with optional item type validation
- `Hash` - Hash validation with optional nested structure validation

### Common Options (used in opts array)
- `required: true|false` - Whether the field is required
- `min: value` - Minimum value/length
- `max: value` - Maximum value/length
- `blank: false` - Prevents blank strings (empty or whitespace-only)
- `format: /regex/` - Regular expression validation
- `in: [values]` - Enum validation (value must be in the specified array)
- `message: "custom message"` - Custom error message for the validation rule

### Hash Structure Options
- `items: [...]` - Array of nested field validations for Hash types (see Hash Validation section)

### Example Usage
```ruby
FIELDS_VALIDATES = {
  account_id_validate: {
    field: :account_id,
    type: Integer,
    opts: [
      { required: true, message: "Account ID is required" }
    ]
  },
  search_criteria_validate: {
    field: :search_criteria,
    type: String,
    opts: [
      { required: true, message: "Search criteria is required" },
      { blank: false, message: "Search criteria cannot be blank" }
    ]
  }
}.freeze
```

### Array Validation
```ruby
# Simple array
tags_validate: { 
  field: :tags, 
  type: Array, 
  opts: [
    { required: false }
  ]
}

# Array with typed items (refer to rails_param gem documentation for complex array validation)
category_ids_validate: { 
  field: :category_ids, 
  type: Array, 
  opts: [
    { required: false }
  ]
}
```

### Hash Validation
```ruby
# Simple hash
metadata_validate: { 
  field: :metadata, 
  type: Hash, 
  opts: [
    { required: false }
  ]
}

# Complex nested hash validation with items array
user_profile_validate: {
  field: :user_profile,
  type: Hash,
  opts: [
    { required: true, message: "User profile is required" }
  ],
  items: [
    { field: :name, type: String, opts: [{ required: true, message: "Name is required" }] },
    { field: :age, type: Integer, opts: [{ required: false }] },
    { field: :email, type: String, opts: [
      { required: true, message: "Email is required" },
      { format: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i, message: "Invalid email format" }
    ]}
  ]
}
```

## Features

- **Automatic Loading**: Validators are automatically loaded based on controller/action names
- **Nested Validation**: Support for validating nested Hash/Array parameters
- **Custom Error Handling**: Detailed error messages with field context
- **Rails Integration**: Seamless integration through Rails controller concerns
- **Generator Commands**: Easy validator generation and management
- **Comprehensive Types**: Support for all major data types and complex nested structures

## Development

### Testing

Run the test example:

```bash
ruby runtest.rb
```

### Building the Gem

```bash
gem build rails_validation_api.gemspec
gem install rails_validation_api-*.gem
```

## Dependencies

- `rails_param` (~> 0.9.0) - Core parameter validation logic
- `activesupport` (>= 6.0) - For Rails utilities and concerns
- `activemodel` (>= 6.0) - For model validation features

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/linhnq-cs/rails_vailidation_api.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
# rails_vailidation_api_test
