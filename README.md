# Rails Validation API

Enhanced parameter validation system for Rails APIs with automatic controller integration.

Rails Validation API provides a powerful DSL for validating request parameters in Rails applications. Features include automatic validator loading based on controller/action names, nested parameter validation, custom error handling, and seamless integration with Rails controllers through concerns. Perfect for API applications requiring robust parameter validation with minimal boilerplate code.

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

### Basic Usage

The gem provides automatic parameter validation through Rails controller concerns. It automatically loads validators based on controller and action names.

#### Example Controller

```ruby
class API::UsersController < ApplicationController
  require "auto_load_rails_validation_api"
  include AutoLoadRailsValidation

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
  #   # Basic string validation
  #   name: { required: true, type: String, min: 2, max: 50 },
  #   
  #   # Email with format validation
  #   email: { required: true, type: String, format: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i },
  #   
  #   # Integer with range validation
  #   age: { required: false, type: Integer, min: 18, max: 120 },
  #   
  #   # Float validation
  #   price: { required: true, type: Float, min: 0.01 },
  #   
  #   # Boolean validation
  #   active: { required: false, type: Boolean },
  #   
  #   # Date validation
  #   birth_date: { required: false, type: Date },
  #   
  #   # DateTime validation
  #   created_at: { required: false, type: DateTime },
  #   
  #   # Enum validation with 'in' option
  #   status: { required: true, type: String, in: %w[active inactive pending] },
  #   
  #   # Array validation
  #   tags: { required: false, type: Array },
  #   
  #   # Array with specific item types
  #   category_ids: { required: false, type: Array, items: { type: Integer } },
  #   
  #   # Hash validation
  #   metadata: { required: false, type: Hash },
  #   
  #   # Nested Hash validation with structure
  #   address: { 
  #     required: false, 
  #     type: Hash,
  #     items: [
  #       { field: :street, type: String, required: true },
  #       { field: :city, type: String, required: true },
  #       { field: :state, type: String, required: true, in: %w[CA NY TX FL] },
  #       { field: :zip_code, type: String, required: true, format: /\A\d{5}(-\d{4})?\z/ },
  #       { field: :country, type: String, required: false, default: "US" }
  #     ]
  #   },
  #   
  #   # Complex nested structure
  #   user_profile: {
  #     required: false,
  #     type: Hash,
  #     items: [
  #       { field: :bio, type: String, required: false, max: 500 },
  #       { field: :social_links, type: Array, required: false,
  #         items: {
  #           type: Hash,
  #           items: [
  #             { field: :platform, type: String, required: true, in: %w[twitter facebook linkedin] },
  #             { field: :url, type: String, required: true, format: /\Ahttps?:\/\// }
  #           ]
  #         }
  #       }
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

### Basic Types
- `String` - String validation with optional min/max length
- `Integer` - Integer validation with optional min/max range
- `Float` - Float validation with optional min/max range
- `Boolean` - Boolean validation (true/false)
- `Date` - Date validation
- `DateTime` - DateTime validation
- `Array` - Array validation with optional item type validation
- `Hash` - Hash validation with optional nested structure validation

### Common Options
- `required: true|false` - Whether the field is required
- `min: value` - Minimum value/length
- `max: value` - Maximum value/length
- `default: value` - Default value if not provided
- `format: /regex/` - Regular expression validation
- `in: [values]` - Enum validation (value must be in the specified array)
- `message: "custom message"` - Custom error message

### Array Validation
```ruby
# Simple array
tags: { type: Array, required: false }

# Array with typed items
category_ids: { type: Array, items: { type: Integer } }

# Array with complex item validation
social_links: { 
  type: Array, 
  items: {
    type: Hash,
    items: [
      { field: :platform, type: String, required: true },
      { field: :url, type: String, required: true, format: /\Ahttps?:\/\// }
    ]
  }
}
```

### Hash Validation
```ruby
# Simple hash
metadata: { type: Hash, required: false }

# Hash with nested structure
address: {
  type: Hash,
  required: true,
  items: [
    { field: :street, type: String, required: true },
    { field: :city, type: String, required: true },
    { field: :zip_code, type: String, format: /\A\d{5}(-\d{4})?\z/ }
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
